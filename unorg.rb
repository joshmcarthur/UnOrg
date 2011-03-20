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

configure do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/unorg.db.sqlite3")
  DataMapper.auto_upgrade!
end

before do
  
end

#General routes
get '/' do
  @number_of_sessions = Session.count
  @number_of_desires = Desire.count
  @sessions = Session.all
  @desires = Session.all
  haml :index
end

#Session routes
get '/sessions' do
  @sessions = Session.all
  haml :"sessions/index"
end

get '/sessions/:id' do
  @session = Session.find(params[:id])
  not_found?(@session)
  haml :"sessions/show"
end

get '/sessions/new' do  
  haml :"sessions/new"
end

get '/sessions/edit/:id' do
  @session = Session.find(params[:id])
  not_found?(@session)
  haml :"sessions/edit"
end

put '/sessions/:id' do
  @session = Session.find(params[:id])
  not_found?(@session)
  
  @session.update_attributes(params[:session])
  pretty_save(@session)
end

post '/sessions' do
  @session = Session.new(params[:session])
  pretty_save(@session)
end


#Desires routes
get '/desires' do
  @desires = Desire.all
end

get '/desires/:id' do
  @desire = Desire.find(params[:id])
  not_found?(@desire)
  haml :"desires/show"
end

get '/desires/:id/upvote' do
  @desire = Desire.find(params[:id])
  not_found?(@desire)
  @desire.upvote!
  redirect '/desires'
end
  

get '/desires/new' do
  haml :"desires/new"
end

post '/desires' do
  @desire = Desire.new(params[:desire])
  pretty_save(@desire)
end

get '/desires/edit' do
  haml :"desires/edit"
end

put '/desires/:id' do
  @desire = Desire.find(params[:id])
  not_found?(@desire)

  @desire.update_attributes(params[:desire])
  pretty_save(@desire)
end

# CRUD helpers
def not_found?(object)
  error(404, IL18N[:"#{object.class.downcase}_not_found"] || I18N[:not_found]) unless object
end

def pretty_save(object, params, return_to = nil)
  return_to = "/#{object.class.downcase.pluralize}" unless return_to
  object.valid? ? (object.save && redirect(return_to)) : error(400, (I18N[:"#{object.class.downcase}_validation_error"] || I18N[:validation_error]))
end
