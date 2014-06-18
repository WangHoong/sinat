require "rubygems"
require "sinatra"
require 'rake'
require "resque/tasks"

Dir[File.expand_path('tasks/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
