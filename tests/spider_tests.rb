require 'minitest/autorun'
require 'celluloid'
require './worker'
require 'open-uri'

BASE_URL = "http://www.sample.com/samplepath"
TEST_URLS = [
  "http://www.ndtv.com/article/world/barack-obama-leaves-afghanistan-after-surprise-troop-visit-530672",
  "http://www.詹姆斯.com/",
  "https://sg.news.yahoo.com/blogs/fit-to-post-autos/brain-cancer-survivor-shawn-low-starts-dream-drive-023034432.html",
  "http://www.adobe.com/enterprise/accessibility/pdfs/acro6_pg_ue.pdf",
  "http://media.npr.org/assets/img/2012/02/02/mona-lisa_custom-31a0453b88a2ebcb12c652bce5a1e9c35730a132-s6-c30.jpg"
]

TEST_FILES_MIME_TYPE = {
  "./tests/web1.html" => "text/html",
  "./tests/web2.html" => "text/html",
  "./tests/web3.html" => "text/html",
  "./tests/adobe1.pdf" => "application/pdf"  
}

TEST_FILES = [
  "./tests/web1.html",
  "./tests/web2.html",
  "./tests/web3.html"
]


TEST_FILES_SIZES = [
  610,
  1012,
  3111
]
TEST_FILES_LINK_SIZES = [
  131,
  114,
  26
]

TEST_MIME_TYPES = [
  "text/html",
  "text/html",  
  "text/html",    
  "application/pdf",
  "image/jpeg" 
]

class TestSpider < MiniTest::Unit::TestCase
  include Spider
  
  def test_normalize
    TEST_URLS.each do |url|
      refute_nil normalize(url) 
    end    
  end
  
  def test_mime_type
    TEST_URLS.each_with_index do |url, i|
      assert_equal TEST_MIME_TYPES[i], simple_mime_type(url) 
    end        
    TEST_FILES_MIME_TYPE.each do |url, type|
      assert_equal type, simple_mime_type(url) 
    end      
  end

  def test_extract_all_words
    TEST_FILES.each_with_index do |file, i|
      html = open(file).read
      assert_equal TEST_FILES_SIZES[i], extract_all_words(html).size 
    end    
    
  end
  
  def test_extract_all_links
    TEST_FILES.each_with_index do |file, i|
      html = open(file).read
      assert_equal TEST_FILES_LINK_SIZES[i], extract_all_links(html, BASE_URL).size      
    end        
  end  
  
end