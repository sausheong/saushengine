require './models'
require './worker'


configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] ||= 'my_saucy_secret'
  set :protection, except: :session_hijacking  
end

helpers Loggable

get "/" do
  conn = Bunny.new
  conn.start
  ch = conn.create_channel
  q = ch.queue "saushengine", durable: true
  @qstatus = q.status
  conn.close  
  @page_count = Page.count
  haml :index
end

get "/spiders" do
  @workers = Celluloid::Actor.all
  haml :spiders
end

get "/add" do
  worker = Worker.new
  Celluloid::Actor[SecureRandom.uuid.to_sym] = worker
  redirect "/spiders"
end

get "/reduce" do
  worker = Celluloid::Actor.all.first
  worker.terminate  
  redirect "/spiders"
end

get "/logs" do
  page = params[:page] || 1
  page_size = params[:page_size] || 10
  @logs = Log.reverse_order(:created_at).paginate(page.to_i, page_size.to_i)
  haml :logs
end

get "/about" do
  haml :about
end