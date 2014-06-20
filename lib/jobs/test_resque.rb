require 'resque'

module Jobs
 class TestResque 
  @queue = :test_resque
  def self.perform(params)
    puts params
    asset = Asset.all.first
    puts asset.id
    log = Logger.new(File.join('log/resque_error.log'))
    log.debug "#{Time.now}--* Test resque debug"
  end
 end
 
end
 
