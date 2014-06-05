#\ -s puma

require 'rubygems'
require 'bundler'
require 'securerandom'

Bundler.require
require './spider-ui'

run Rack::URLMap.new "/" => Sinatra::Application