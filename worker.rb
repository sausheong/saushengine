require 'bunny'
require './models'
require 'stemmer'
require 'robots'
require 'open-uri'
require 'nokogiri'
require 'addressable/uri'
require 'rest-client'
require 'mime-types'

#  to scrape the url, create pages

module Spider
  
  def index(url)
    
    uri = normalize(url)
    page = Page[url: uri.to_s]
    
    if !page.nil? and page.updated_at > (DateTime.now - 1).to_time 
      puts "already indexed"
      return
    end

    if page.nil?
      type = simple_mime_type(url)
      page = Page.create(url: uri.to_s, host: uri.host, mime_type: type)        
    end
    # delete existing locations
    page.remove_all_locations
    
    words = extract_words(url)
    words.each_with_index do |word, index|
      stem = word.downcase.stem
      w = Word.find_or_create(stem: stem)
      Location.create(word: w, page: page, position: index)
    end
    links = extract_links(uri.to_s)
    add_to_queue(links)
  end
  
  def normalize(url)
    Addressable::URI.parse(url).normalize
  end
  
  def simple_mime_type(url)
    uri = normalize(url).to_s
    content_type = RestClient.head(uri).headers[:content_type]
    MIME::Type.new(content_type).simplified
  end

  # i. If it is a relative url, add the base url
  # ii. If authentication is required, add in user name and password   
  def extract_links(base)
    []
  end
  
  # extract words and keywords and return an array
  def extract_words(url)
    words, keywords = [], []
    keywords + words
  end  
  
  # add to queue
  def add_to_queue(links)
    
  end
  

end

class Worker
  include Celluloid, Loggable, Spider

  finalizer :finalizer
  
  def initialize()
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
          p body
          

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


