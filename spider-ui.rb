require './models'
require './spider'
require 'open-uri'

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

post "/spiders/add" do
  number = params[:num].to_i
  number.times do 
    worker = Worker.new
    Celluloid::Actor[SecureRandom.uuid.to_sym] = worker
  end
  redirect "/"
end

get "/spiders/clear" do
  workers = Celluloid::Actor.clear_registry
  workers.values.each do |worker|
    worker.terminate  
  end
  redirect "/"
end

get "/logs" do
  @current_page = (params[:page] || 1).to_i
  page_size = params[:page_size] || 100
  @logs = Log.reverse_order(:created_at).paginate(@current_page.to_i, page_size.to_i)
  start_pg = (@current_page < 6) ? 0 : @current_page - 2
  end_pg = (@current_page > @logs.page_count - 4) ? @logs.page_count : @current_page + 2
  @page_range = start_pg..end_pg  
  haml :logs
end

get "/settings" do
  @config = open('spider.cfg').read
  haml :settings  
end

post "/settings" do
  text = params[:config]
  open('spider.cfg', 'w') do |f|
    f.puts text
  end
  redirect "/settings"
end

get "/add_url" do
  haml :add_url  
end

post "/add_url" do
  conn = Bunny.new
  conn.start
  ch = conn.create_channel
  q = ch.queue "saushengine", durable: true
  q.publish params[:url], persistent: true
  conn.close
  redirect "/"  
end


get "/about" do
  haml :about
end