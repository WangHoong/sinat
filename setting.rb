require 'sinatra'
require "sinatra/config_file"

class Setting < Sinatra::Base  
  register Sinatra::ConfigFile
  config_file 'config/application.yml'
end
 
