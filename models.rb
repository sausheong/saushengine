require 'sequel'
require 'jdbc/postgres'
Jdbc::Postgres.load_driver

TIME_FORMAT = 'UTC %l:%M %p'
DATE_FORMAT = '%d-%b-%Y'
DATETIME_FORMAT = '%k:%M, %d-%b-%y'
DB = Sequel.connect 'jdbc:postgresql://localhost:5432/saushengine2?user=saushengine2&password=saushengine2'
DB.extension :pagination

module Loggable
  DEBUG, INFO, WARN, ERROR = 1, 2, 3, 4
  def info(message)
    Log.create(content: message, level: INFO)
  end  
  
  def debug(message)
    Log.create(content: message, level: DEBUG)
  end  
  
  def warn(message)
    Log.create(content: message, level: WARN)
  end  
  
  def error(message)
    Log.create(content: message, level: ERROR)
  end    
end

class Page < Sequel::Model
  one_to_many :locations
  def before_create
    super
    self.created_at = DateTime.now
    self.updated_at = DateTime.now
  end   
end

class Word < Sequel::Model
  one_to_many :locations 
end

class Location < Sequel::Model
  many_to_one :page
  many_to_one :word  
end

class Log < Sequel::Model
  include Loggable
  def before_create
    super
    self.created_at = DateTime.now
  end   
end