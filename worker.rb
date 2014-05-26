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

module Scraper
  
  def scrape(url)
    
    scrubbed_url = scrub(url)
    page = Page[url: scrubbed_url.to_s]
    # new page
    if page.nil? then
      type = simple_mime_type(url)
      page = Page.create(url: scrubbed_url.to_s, host: scrubbed_url.host, mime_type: type)
    
    # existing page
    else
      # check if updated in the last 1 day
      if page.updated_at < (DateTime.now - 1) then
        
      end

    end
    
  end
  
  def scrub(url)
    Addressable::URI.parse(url).normalize
  end
  
  def simple_mime_type(url)
    uri = scrub(url).to_s
    content_type = RestClient.head(uri).headers[:content_type]
    MIME::Type.new(content_type).simplified
  end
  
end

# to extract links and words from a link

module Extractor
  def extract_links(base, link)
    
  end
  
  def extract_words(link)
    
  end
end

class Worker
  include Celluloid, Loggable, Scraper

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


