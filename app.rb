require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'erb'
require 'mini_magick'
require "sinatra/config_file"
require './setting'
require './application_helper'
require './sleeper'
require './assets'


Dir[File.expand_path('models/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

Dir[File.expand_path('lib/jobs/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
 

env = ENV['RACK_ENV'] || :development
resque_config = YAML.load_file('config/resque.yml')
Resque.redis = resque_config[env]
 
 
helpers ApplicationHelper 

Mongoid.load!("config/mongoid.yml")
   
 
   get '/' do
     @assets = Asset.all.limit(10)
     erb :index
   end

  get '/new'  do
     Resque.enqueue(Sleeper,{:id=>'ok'})
     erb :new
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
 
 
