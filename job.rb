require 'resque'
require 'sinatra'
require 'mongoid'
require 'mini_magick'
require 'sinatra/config_file'
require './setting'

#Models
Dir[File.expand_path('models/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
#Job
Dir[File.expand_path('lib/jobs/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
Mongoid.load!("config/mongoid.yml")

 
