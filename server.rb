require './models'
require './worker'

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'my_saucy_secret'
  set :protection, except: :session_hijacking  
end

helpers Loggable

get "/" do
  @workers = Celluloid::Actor.all
  haml :index
end

get "/add" do
  worker = Worker.new
  Celluloid::Actor[SecureRandom.uuid.to_sym] = worker
  redirect "/"
end

get "/reduce" do
  worker = Celluloid::Actor.all.first
  worker.terminate  
  redirect "/"
end

get "/logs" do
  page = params[:page] || 1
  page_size = params[:page_size] || 10
  @logs = Log.reverse_order(:created_at).paginate(page.to_i, page_size.to_i)
  haml :logs
end