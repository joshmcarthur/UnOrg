require 'bundler/setup'

require 'sinatra'
require 'haml'

require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-observer'


APP_DIR = File.expand_path(File.dirname(__FILE__))
MODELS_DIR = File.join(APP_DIR, 'models')
PUBLIC_DIR = File.join(APP_DIR, 'public')

require File.join(MODELS_DIR, 'session.rb')
require File.join(MODELS_DIR, 'desire.rb')


#Setup
I18N = {
  :session_not_found => "Session not found.",
  :session_validation_error => "Session could not be saved; invalid data.",
  :desire_not_found => "Desire not found.",
  :desire_validation_error => "Desire could not be saved; invalid data.",
  :not_found => "Record not found",
  :validation_error => "Record could not be saved; invalid data."
}

set :public, PUBLIC_DIR

configure :test do
  DataMapper.setup(:default, "sqlite3::memory")
  DataMapper.auto_upgrade!
end

configure do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/unorg.db.sqlite3")
  DataMapper.auto_upgrade!
end

before do
  @flash = {:notice => nil, :error => nil}
end

#General routes
get '/' do
  @sessions = Session.display
  @desires = Desire.all
  haml :index
end

#Session routes
get '/sessions/new' do  
  haml :"sessions/new"
end

get '/sessions/:id/edit' do
  @session = Session.get(params[:id])
  not_found?(@session)
  haml :"sessions/edit"
end

post '/sessions/:id/update' do
  @session = Session.get(params[:id])
  not_found?(@session)
  params[:session] ||= {}
  @session.update!(params[:session])
  pretty_update(@session)
end

post '/sessions/:id/delete' do
  @session = Session.get(params[:id])
  not_found?(@session)
  @session.destroy
  redirect '/'
end

post '/sessions' do
  @session = Session.new(params[:session])
  pretty_save(@session)
end


#Desires routes
get '/desires/new' do
  haml :"desires/new"
end

post '/desires/:id/upvote' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)
  @desire.upvote!
  redirect '/'
end

post '/desires/:id/delete' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)
  @desire.destroy
  redirect '/'
end

post '/desires' do
  @desire = Desire.new(params[:desire])
  pretty_save(@desire)
end

get '/desires/:id/edit' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)
  
  haml :"desires/edit"
end

post '/desires/:id/update' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)

  @desire.update(params[:desire])
  pretty_update(@desire)
end

post '/desires/:id/resolve' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)
  
  @desire.resolve!
  redirect '/'
end

post '/desires/:id/close' do
  @desire = Desire.get(params[:id])
  not_found?(@desire)
  
  @desire.close!
  redirect '/'
end



# CRUD helpers
def not_found?(object)
  error(404, I18N[:"#{object.class.name.downcase}_not_found"] || I18N[:not_found]) unless object
end

def pretty_save(object, return_to = nil, do_save = true)
  return_to = "/" unless return_to
  object.valid? ? ((do_save ? object.save : true) && redirect(return_to)) : error(400, (I18N[:"#{object.class.name.downcase}_validation_error"] || I18N[:validation_error]))
end

def pretty_update(object, return_to = nil)
  pretty_save(object, return_to, false)
end
