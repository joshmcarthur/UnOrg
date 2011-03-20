# Load the Sinatra app
require File.dirname(__FILE__) + '/../unorg'

require 'rspec'
require 'rack/test'

set :environment, :test

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  Sinatra::Application
end
