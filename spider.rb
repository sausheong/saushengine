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


module Spider
  
  # HTML Spider - extracts text and links for text/html files
  class HTML
    
    # get the raw text from the url; here it is HTML
    def get_raw_text(url, options)
      if options[:ntlm]
        begin
          u = Addressable::URI.parse(url).normalize
          http = Net::HTTP.new(u.hostname)
          request = Net::HTTP::Get.new(u.path)
          request.ntlm_auth(options[:user], options[:domain], options[:pass])
          html = http.request(request).body
        rescue
          p $!
          # do nothing for now
        end
      else
        html = open(url).read
      end
      html
    end

    # If it is a relative url, add the base url
    def extract_all_links(type, html, base)
      links = []
      if type == "text/html"        
        base_url = URI.parse(base)
        doc = Nokogiri::HTML(html)
        
        doc.css("a").each do |node|      
          begin
            uri = URI(node['href'])
            if uri.absolute? and uri.scheme != "javascript"     
              links << uri.to_s
            elsif uri.path.start_with?("/")
              uri = base_url + uri
            end
          rescue
            # don't do anything
          end
        end    
        links.uniq        
      end
      return links
    end
  
    # extract the title of this text
    def extract_title(html)
      doc = Nokogiri::HTML(html)
      node = doc.css("title")
      if node.nil?
        return ""
      else
        return node.text.strip
      end
    end
  
    # extract words and keywords and return an array
    def extract_all_words(html)
      doc = Nokogiri::HTML(html)
      keywords = []
      doc.css("meta[name='keywords']").each do |node|
        keywords += node['content'].gsub(/\s+/, " ").gsub(/[^a-zA-Z\- ',]/, '').squeeze(" ").split(",")
      end
      text = String.new
      doc.css("meta[name='description']").each do |node|
        text += node['content']
      end
    
      %w(script style link meta).each do |tag|
        doc.css(tag).each { |node| node.remove }
      end

      w = []
      doc.traverse do |node|
        if node.text? then
          w << node.content + " "
        end
      end
      text += w.join.gsub(/\s+/, " ").gsub(/[^a-zA-Z\- ']/, '').squeeze(" ")
      words = (text.downcase.split - STOPWORDS)
    
      final = (keywords + words)
      final.map do |w|
        w.stem
      end
    end  
  
  
    # add to queue
    def add_to_queue(links, options)
      conn = Bunny.new
      conn.start
      ch = conn.create_channel
      q = ch.queue "saushengine", durable: true
      
      if options[:domains] == "*"
        links.each do |link|
          q.publish link, persistent: true
        end        
      else 
        domains = options[:domains].split(",").map{|i| i.strip}
        links.each do |link|
          uri = Addressable::URI.parse(link).normalize
          if domains.map{|d| uri.hostname.end_with?(d)}.inject(:|)
            q.publish link, persistent: true
          end
        end        
      end
      conn.close    
    end    

  end

  # index this url
  def index(url, options)
    uri = Addressable::URI.parse(url).normalize
    page = Page[url: uri.to_s]
    
    if !page.nil? and page.updated_at > (DateTime.now - 1).to_time 
      info "#{url[0..20]}... - already indexed"
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
      Loggable.log "No spiders found for mime-type #{type}"
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
          puts "Start indexing #{body}"
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


