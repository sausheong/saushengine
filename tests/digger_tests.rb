require 'minitest/autorun'
require './digger'

class TestDigger < MiniTest::Unit::TestCase
  
  def test_search
    d = Digger.new
    p d.search("Malaysia Airline")
  end

end