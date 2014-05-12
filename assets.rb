require 'sinatra/base'
require 'sinatra/flash'
require 'erb'
require 'mongoid'
require './application_helper'

class Assets <  Sinatra::Base
 helpers ApplicationHelper 
 
 set :views, File.expand_path('../views', __FILE__)

  get '/assets/hel' do
    'sdsdsdssds'
  end
 
  get '/assets/about' do
    'ssssss'
  end
end
