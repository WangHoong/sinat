require 'resque'

namespace :resque_work do
  desc "resque_work"
  task 'stop'  do
     pids = Array.new
     Resque.workers.each do |worker|
        pids.concat(worker.worker_pids)        
     end
     if pids.empty?
        puts "no worker"
     else
        syscmd = "kill -s QUIT #{pids.join(' ')}"
        puts "Running cmd #{syscmd}"
        system(syscmd)
     end
  end
   
  



end
