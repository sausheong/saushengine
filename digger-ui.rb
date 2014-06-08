require './models'
require './digger'
require './mimetypes'

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'my_saucy_secret'
  set :protection, except: :session_hijacking  
end

helpers Loggable

get "/" do
  types = DB["select mime_type from pages group by mime_type"].all.map{|i| i[:mime_type]}
  p types
  @mime_types = MIMETYPES.delete_if {|k,v| !types.include?(k)}
  p @mime_types
  haml :search, layout: :digger_layout
end

post "/q" do
  types = DB["select mime_type from pages group by mime_type"].all.map{|i| i[:mime_type]}
  p types
  @mime_types = MIMETYPES.delete_if {|k,v| !types.include?(k)}
  p @mime_types
  digger = Digger.new
  
  options = {
    ranks: {frequency: 0.60, location: 0.20, distance: 0.20 }, 
    size: 50, 
    mime_type: params[:mime_type]
  }
  
  results = digger.search params[:text], options
  @pages = results.map do |pg|
    Page[pg[0]]
  end
  haml :results, layout: :digger_layout
end
