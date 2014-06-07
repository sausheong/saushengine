require './stopwords'
require './models'
require 'stemmer'
require 'robots'
require 'open-uri'
require 'nokogiri'
require 'addressable/uri'
require 'rest-client'
require 'mime-types'
require 'bunny'
require 'mimemagic'
require 'ntlm/http'
require 'rika'

Dir.new("#{File.dirname(__FILE__)}/spiders").each { |lib| require "./spiders/#{lib}" if File.extname(lib) == '.rb' }


module Spider

  # index this url
  def index(url, options)
    uri = Addressable::URI.parse(url).normalize
    page = Page[url: uri.to_s]
    
    if !page.nil? and page.updated_at > (DateTime.now - 1).to_time 
      info "#{url[0..40]}... - already indexed"
      return
    end

    type = simple_mime_type(url, options)  

    spider = get_spider(type)

    text = spider.get_raw_text(url, options)

    if page.nil?
      title = spider.extract_title text
      page = Page.create(title: title, url: uri.to_s, host: uri.host, mime_type: type)        
    end
    # delete existing locations
    page.remove_all_locations

    words = spider.extract_all_words text

    words.each_with_index do |word, index|
      stem = word.downcase.stem
      w = Word.find_or_create(stem: stem)
      Location.create(word: w, page: page, position: index)
    end
    
    unless options[:do_not_extract_link]
      links = spider.extract_all_links(type, text, url)    
      unless links.nil? or links.empty?
        spider.add_to_queue(links, options)
      end
    end
  end

  # get the simple mime-type of the given URL
  def simple_mime_type(url, options)
    uri = Addressable::URI.parse(url).normalize
    if uri.scheme == "https" or uri.scheme == "http"
      if options[:ntlm]
        http = Net::HTTP.new(uri.hostname)
        request = Net::HTTP::Head.new(uri.path)
        request.ntlm_auth(options[:user], options[:domain], options[:pass])
        content_type = http.request(request)['content-type']        
      else        
        content_type = RestClient.head(uri.to_s).headers[:content_type]
      end
    else
      content_type = MimeMagic.by_magic(File.open(uri.to_s)).type
    end
    MIME::Type.new(content_type).simplified
  end
  
  # get the correct spider to extract the text
  def get_spider(type)
    if type == "text/html"
      return HTML.new
    else
      return Tika.new
    end
  end
end

class Worker
  include Celluloid, Loggable, Spider

  finalizer :finalizer
  
  def initialize(options={})
    @options = options
    @conn = Bunny.new(automatically_recover: true)
    @conn.start
    @channel = @conn.create_channel
    @queue = @channel.queue("saushengine", durable: true)    
    @exchange = @channel.default_exchange
    @channel.prefetch 1
    info "A new worker has started"
    async.run
  end
  
  def run
    begin
      @consumer = @queue.subscribe(manual_ack: true, block: false) do |delivery_info, properties, body|
        begin
          puts "Start indexing - #{body}"
          options = YAML.load(open('spider.cfg').read)
          options[:do_not_extract_link] = true if @queue.message_count > options[:link_extraction_limit]
          if options[:ntlm]
            options[:user], options[:domain], options[:pass] = $ntlm[:ntlm_user], $ntlm[:ntlm_domain], $ntlm[:ntlm_pass]
          end
          index body, options
        rescue Exception => exception
          error exception.message
        end
        @channel.ack(delivery_info.delivery_tag)
      end
      
    rescue Interrupt => int
      error int.message
      @channel.close
      @conn.close
    end
  end
  
  def finalizer
    @consumer.cancel
    @conn.close    
    warn "#{self.name} has died"
  end
end


