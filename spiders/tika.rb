require 'tempfile'

module Spider
  
  # Tika Spider - Apache Tika based spider that extracts everything else other than HTML
  # http://tika.apache.org/
  # List of file formats that Tika extracts - http://tika.apache.org/1.5/formats.html
  class Tika
    
    # get the raw text from the url
    def get_raw_text(url, options)
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
      text, @title = String.new, String.new
      Tempfile.open("temp-#{rand(1000)}") do |f|
        f.write data
        text, metadata = Rika.parse_content_and_metadata f.path
        if metadata['title']
          @title = metadata['title']
        else
          @title = File.basename(u.path)
        end
      end
      return text
    end

    # Returns nothing
    def extract_all_links(type, html, base)
      []
    end
  
    # extract the title of this text
    def extract_title(html)
      @title
    end
  
    # extract words and keywords and return an array
    def extract_all_words(raw_text)
      text = raw_text.gsub(/\s+/, " ").gsub(/[^a-zA-Z\- ']/, '').squeeze(" ")
      words = (text.downcase.split - STOPWORDS)
      words.map do |w|
        w.stem
      end
    end  
  
  
    # add to queue
    def add_to_queue(links, options)
      # doesn't add anything to the queue
    end    

  end
end