require 'minitest/autorun'
require 'celluloid'
require './worker'

TEST_URLS = [
  "http://www.ndtv.com/article/world/barack-obama-leaves-afghanistan-after-surprise-troop-visit-530672",
  "http://www.詹姆斯.com/",
  "http://www.adobe.com/enterprise/accessibility/pdfs/acro6_pg_ue.pdf",
  "http://media.npr.org/assets/img/2012/02/02/mona-lisa_custom-31a0453b88a2ebcb12c652bce5a1e9c35730a132-s6-c30.jpg"
]

TEST_MIME_TYPES = [
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
  end

  
end