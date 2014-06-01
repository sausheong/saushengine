require './models'
require './digger'


configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'my_saucy_secret'
  set :protection, except: :session_hijacking  
end

helpers Loggable

get "/" do
  haml :search, layout: :digger_layout
end

post "/q" do
  digger = Digger.new
  @results = digger.search params[:text]
  haml :results, layout: :digger_layout
end
