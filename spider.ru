#\ -s puma

require 'rubygems'
require 'bundler'
require 'securerandom'

Bundler.require
require './server'

run Rack::URLMap.new "/" => Sinatra::Application