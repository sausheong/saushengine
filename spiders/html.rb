module Spider
  
  # HTML Spider - extracts text and links for text/html files
  class HTML
    attr_accessor :options, :text, :title, :words, :links
    
    # get the raw text from the url; here it is HTML
    def parse(url, options)
      @options = options
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
      @text = html
      @links = extract_all_links(html, url)
      @title = extract_title(html)
      @words = extract_all_words(html)
    end
  
    # add to queue
    def add_to_queue
      conn = Bunny.new
      conn.start
      ch = conn.create_channel
      q = ch.queue "saushengine", durable: true
      
      if @options[:domains] == "*"
        @links.each do |link|
          q.publish link, persistent: true
        end        
      else 
        domains = @options[:domains].split(",").map{|i| i.strip}
        @links.each do |link|
          uri = Addressable::URI.parse(link).normalize
          if domains.map{|d| uri.hostname.end_with?(d)}.inject(:|)
            q.publish link, persistent: true
          end
        end        
      end
      conn.close    
    end    

    private
    
    # If it is a relative url, add the base url
    def extract_all_links(html, base)
      links = []
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
  

  end
end