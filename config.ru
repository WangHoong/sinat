require "rubygems"
require "sinatra"

require './app'
require 'resque/server'
run Sinatra::Application

