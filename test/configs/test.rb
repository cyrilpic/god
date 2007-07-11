if $0 == __FILE__
  require File.join(File.dirname(__FILE__), *%w[.. .. lib god])
end

RAILS_ROOT = "/Users/tom/dev/git/helloworld"

God.meddle do |god|
  god.watch do |w|
    w.name = "local-3000"
    w.interval = 5 # seconds
    w.start = "mongrel_rails start -P ./log/mongrel.pid -c #{RAILS_ROOT} -d"
    w.stop = "mongrel_rails stop -P ./log/mongrel.pid -c #{RAILS_ROOT}"
    w.grace = 5
    
    pid_file = File.join(RAILS_ROOT, "log/mongrel.pid")
    
    # clean pid files before start if necessary
    w.behavior(:clean_pid_file) do |b|
      b.pid_file = pid_file
    end
    
    # determine the state on startup
    w.lifecycle(:init, [:up, :start]) do |start|
      start.condition(:process_running) do |c|
        c.running = true
        c.pid_file = pid_file
      end
    end
    
    # determine when process has finished starting
    w.lifecycle([:start, :restart], :up) do |up|
      up.condition(:http) do |c|
        
      end
    end
  
    # start if process is not running
    w.lifecycle(:up, :start) do |start|
      start.condition(:process_exits) do |c|
        c.pid_file = pid_file
      end
    end
    
    # restart if memory or cpu is too high
    w.lifecycle(:up, :restart) do |restart|
      restart.condition(:memory_usage) do |c|
        c.interval = 20
        c.pid_file = pid_file
        c.above = (50 * 1024) # 50mb
        c.times = [3, 5]
      end
      
      restart.condition(:cpu_usage) do |c|
        c.interval = 10
        c.pid_file = pid_file
        c.above = 10 # percent
        c.times = [3, 5]
      end
    end
  end
  
  # clear old session files
  # god.watch do |w|
  #   w.name = "local-session-cleanup"
  #   w.start = lambda do
  #     Dir["#{RAILS_ROOT}/tmp/sessions/ruby_sess.*"].select do |f|
  #       File.mtime(f) < Time.now - (7 * 24 * 60 * 60)
  #     end.each { |f| File.delete(f) }
  #   end
  #   
  #   w.start_if do |start|
  #     start.condition(:always)
  #   end
  # end
end

__END__

init -> start -> up -> 