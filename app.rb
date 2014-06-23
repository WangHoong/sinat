require 'rubygems'
require 'sinatra/base'
require "sinatra/config_file"
require 'mongoid'
require 'erb'
require 'mini_magick'
require './setting'
require './application_helper'
require 'rest-client'
require 'resque'
require "bson"
require 'redis'
#require 'newrelic_rpm'

#Models
Dir[File.expand_path('models/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

#Job
Dir[File.expand_path('lib/jobs/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
Mongoid.load!("config/mongoid.yml")

#Resque
env = ENV['RACK_ENV'] || :development
resque_config = YAML.load_file('config/resque.yml')
Resque.redis = resque_config[env]
 
#config_file 'config/newrelic.yml'

#Redis
host, port = Setting.settings.resque_server.split(':')
$redis = Redis.new(:host => host || '127.0.0.1', :port => port || 6379, :thread_safe => true)

#Views
set :views, File.expand_path('../views', __FILE__)


 

class App < Sinatra::Base
#Helpers
 helpers ApplicationHelper 
 get '/' do
     @assets = Asset.all.limit(10)   
     asset = @assets.first
     #Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id})  
     
 #Resque.enqueue(Jobs::UploadAdImage,{:id=>asset.id,:asset_id=>asset.id,:position=>'stuff'})
     
     #Resque.enqueue(Jobs::TestResque,"Processed a job!")
     
     erb :index
   end

  get '/new'  do      
     erb :new
  end
 
  post '/upload_image'  do
   file = params[:image][:tempfile]
   file_format = params[:image][:filename].split(".").last
 
  #url = "http://localhost:3002/zone/arts/save_attach"
   #res = RestClient::Request.execute(:method =>:post, :url => url, :timeout => 120, :open_timeout => 120, :payload => {:asset_id=>'538eeaa1244a3f4dfa000002',:file=>file})

    redirect :new
     
  end

  post '/upload'  do
     file = params[:image][:tempfile]
     file_type = params[:image][:type]
     filename = params[:image][:filename]
     asset_type = params[:asset_type] || Asset::ASSET_TYPE[:art]
     image = MiniMagick::Image.open(file.path)
     image_info = {
          :width   => image[:width],
          :height  => image[:height],
          :size    => image[:size],
          :mime_type => image.mime_type,
          :filename  => filename,
          :asset_type => asset_type,         
          :img_type => image[:format]
        }      
     @asset = Asset.new(image_info)
    
     if @asset.save
         @asset.upload_asset_original_file(image)

        Resque.enqueue(Jobs::ImageUpload,{:id=>@asset.id})
     end
 
     redirect '/'
  end
   
 end
 
