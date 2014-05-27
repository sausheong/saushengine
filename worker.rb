require 'bunny'
require './models'
require 'stemmer'
require 'robots'
require 'open-uri'
require 'nokogiri'
require 'addressable/uri'
require 'rest-client'
require 'mime-types'
require 'bunny'


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
    
    words = extract_all_words(url)
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
  def extract_all_words(url)
    
    doc = Nokogiri::HTML(RestClient.get(url).to_s)
    text = doc.xpath("//text()").to_s
    
    words, keywords = [], []
    keywords + words
  end  
  
  
  # add to queue
  def add_to_queue(links)
    conn = Bunny.new
    conn.start
    ch = conn.create_channel
    q = ch.queue "saushengine", durable: true
    links.each do |link|
      q.publish link, persistent: true
    end
    conn.close    
  end
  

  # Returns the text in UTF-8 format with all HTML tags removed
  #
  # TODO: add support for DL, OL
  def convert_to_text(html, line_length = 65, from_charset = 'UTF-8')
    txt = html

    # replace images with their alt attributes
    # for img tags with "" for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt="" />
    # <img alt="">
    txt.gsub!(/<img.+?alt=\"([^\"]*)\"[^>]*\>/i, '\1')

    # for img tags with '' for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt='' />
    # <img alt=''>
    txt.gsub!(/<img.+?alt=\'([^\']*)\'[^>]*\>/i, '\1')

    # links
    txt.gsub!(/<a.+?href=\"(mailto:)?([^\"]*)\"[^>]*>((.|\s)*?)<\/a>/i) do |s|
      if $3.empty?
        ''
      else
        $3.strip + ' ( ' + $2.strip + ' )'
      end
    end

    txt.gsub!(/<a.+?href='(mailto:)?([^\']*)\'[^>]*>((.|\s)*?)<\/a>/i) do |s|
      if $3.empty?
        ''
      else
        $3.strip + ' ( ' + $2.strip + ' )'
      end
    end

    # handle headings (H1-H6)
    txt.gsub!(/(<\/h[1-6]>)/i, "\n\\1") # move closing tags to new lines
    txt.gsub!(/[\s]*<h([1-6]+)[^>]*>[\s]*(.*)[\s]*<\/h[1-6]+>/i) do |s|
      hlevel = $1.to_i

      htext = $2
      htext.gsub!(/<br[\s]*\/?>/i, "\n") # handle <br>s
      htext.gsub!(/<\/?[^>]*>/i, '') # strip tags

      # determine maximum line length
      hlength = 0
      htext.each_line { |l| llength = l.strip.length; hlength = llength if llength > hlength }
      hlength = line_length if hlength > line_length

      case hlevel
        when 1   # H1, asterisks above and below
          htext = ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength)
        when 2   # H1, dashes above and below
          htext = ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength)
        else     # H3-H6, dashes below
          htext = htext + "\n" + ('-' * hlength)
      end

      "\n\n" + htext + "\n\n"
    end

    # wrap spans
    txt.gsub!(/(<\/span>)[\s]+(<span)/mi, '\1 \2')

    # lists -- TODO: should handle ordered lists
    txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
    # list not followed by a newline
    txt.gsub!(/<\/li>[\s]*(?![\n])/i, "\n")

    # paragraphs and line breaks
    txt.gsub!(/<\/p>/i, "\n\n")
    txt.gsub!(/<br[\/ ]*>/i, "\n")

    # strip remaining tags
    txt.gsub!(/<\/?[^>]*>/, '')

    # decode HTML entities
    he = HTMLEntities.new
    txt = he.decode(txt)

    txt = word_wrap(txt, line_length)

    # remove linefeeds (\r\n and \r -> \n)
    txt.gsub!(/\r\n?/, "\n")

    # strip extra spaces
    txt.gsub!(/\302\240+/, " ") # non-breaking spaces -> spaces
    txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
    txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

    # no more than two consecutive newlines
    txt.gsub!(/[\n]{3,}/, "\n\n")

    # no more than two consecutive spaces
    txt.gsub!(/ {2,}/, " ")

    # the word messes up the parens
    txt.gsub!(/\([ \n](http[^)]+)[\n ]\)/) do |s|
      "( " + $1 + " )"
    end

    txt.strip
  end

  # Taken from Rails' word_wrap helper (http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-word_wrap)
  def word_wrap(txt, line_length)
    txt.split("\n").collect do |line|
      line.length > line_length ? line.gsub(/(.{1,#{line_length}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
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


