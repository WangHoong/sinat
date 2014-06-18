require 'resque'

module Jobs
 class Upload 
  @queue = :upload
  def self.perform(options={})
    puts "Processed a job!"
    asset = Asset.all.first
    puts asset.id
    log = Logger.new(File.join('log/resque_error.log'))
    log.debug "#{Time.now}--* Test resque debug"
  end
 end
 
end
 
