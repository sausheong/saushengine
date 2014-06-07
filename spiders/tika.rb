require 'tempfile'

module Spider
  
  # Tika Spider - Apache Tika based spider that extracts everything else other than HTML
  # http://tika.apache.org/
  # List of file formats that Tika extracts - http://tika.apache.org/1.5/formats.html
  class Tika
    attr_accessor :options, :text, :title, :words, :links
    
    # get the raw text from the url
    def parse(url, options)
      @options = options
      u = Addressable::URI.parse(url).normalize
      if options[:ntlm]
        begin          
          http = Net::HTTP.new(u.hostname)
          request = Net::HTTP::Get.new(u.path)
          request.ntlm_auth(options[:user], options[:domain], options[:pass])
          data = http.request(request).body
        rescue
          p $!
          # do nothing for now
        end
      else
        data = open(url).read
      end
      @text, @title = String.new, String.new
      Tempfile.open("temp-#{rand(1000)}") do |f|
        f.write data
        @text, metadata = Rika.parse_content_and_metadata f.path
        if metadata['title']
          @title = metadata['title']
        else
          @title = File.basename(u.path)
        end
      end
      @links = []
      @words = extract_all_words(@text)
    end
    
    # add to queue
    def add_to_queue
      # doesn't add anything to the queue
    end    
    
    private 
    
    # extract words and keywords and return an array
    def extract_all_words(raw_text)
      text = raw_text.gsub(/\s+/, " ").gsub(/[^a-zA-Z\- ']/, '').squeeze(" ")
      words = (text.downcase.split - STOPWORDS)
      words.map do |w|
        w.stem
      end
    end  

  end
end