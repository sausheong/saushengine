#\ -s puma

require 'rubygems'
require 'bundler'
require 'securerandom'

Bundler.require
require './digger-ui'

run Rack::URLMap.new "/" => Sinatra::Application