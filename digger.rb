require './stopwords'
require 'stemmer'
require './models'
require 'benchmark'

module Ranker
  def words_from(string)
    words = string.gsub(/[^a-zA-Z\- ']/,"").split
    words.map { |word| word.downcase.stem unless (STOPWORDS.include?(word) or word.size > 50) }
  end  
  
  
  def frequency(common_select, found_words)
    freq_sql= "select loc0.page_id, count(loc0.page_id) as count #{common_select} order by count desc"
    list = DB.fetch(freq_sql).all
    rank = {}
    list.size.times { |i| rank[list[i][:page_id]] = list[i].count.to_f/list[0].count.to_f }  
    return rank
  end  
  
  def location(common_select, found_words)
    total, group_bys = [], []
    found_words.each_with_index { |w, index| total << "loc#{index}.position + 1"; group_bys << "loc#{index}.position" }
    loc_sql = "select loc0.page_id, (#{total.join(' + ')}) as total #{common_select}, #{group_bys.join(", ")} order by total asc" 
    list = DB.fetch(loc_sql).all
    rank = {}
    list.size.times { |i| rank[list[i][:page_id]] = list[0][:total].to_f/list[i][:total].to_f }
    return rank
  end
  
  def distance(common_select, found_words)
    return {} if found_words.count == 1
    dist, total = [], []
    found_words.each_with_index { |w, index| total << "loc#{index}.position" }    
    total.size.times { |index| dist << "abs(#{total[index]} - #{total[index + 1]})" unless index == total.size - 1 }    
    dist_sql = "select loc0.page_id, (#{dist.join(' + ')}) as dist #{common_select}, #{total.join(", ")} order by dist asc"  
    list = DB.fetch(dist_sql).all
    rank = Hash.new
    list.size.times { |i| rank[list[i][:page_id]] = list[0][:dist].to_f/list[i][:dist].to_f }
    return rank
  end  
end

class Digger
  include Ranker
  attr_accessor :options
  
  def search(text, options={ranks: {frequency: 0.34, location: 0.33, distance: 0.33 }, size: 50})
    @options = options
    search_words = words_from text
      
    found_words = Word.where(stem: search_words)
    return [] if found_words.count == 0
    
    tables, joins, ids = [], [], []
    found_words.each_with_index { |w, index|
      tables << "locations loc#{index}"
      joins << "loc#{index}.page_id = loc#{index+1}.page_id"
      ids << "loc#{index}.word_id = #{w.id}"    
    }
    joins.pop
    common_select = "from #{tables.join(', ')} where #{(joins + ids).join(' and ')} group by loc0.page_id"  
    rankings = []
    options[:ranks].each do |algorithm, importance|
      rankings << self.send(algorithm, common_select, found_words)
    end
    results = merge rankings
    results[0..49]
  end
  
  def merge(rankings)
    r = {}
    rankings.each do |ranking|
      r.merge!(ranking) do |key, oldval, newval|
        oldval + newval
      end
    end
    r.sort do |a, b|  
      b[1] <=> a[1]
    end    
  end
  

end


