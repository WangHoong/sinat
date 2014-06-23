require 'newrelic_rpm'
require './app.rb'

require 'new_relic/rack/developer_mode'

use NewRelic::Rack::DeveloperMode

run App.new
 


