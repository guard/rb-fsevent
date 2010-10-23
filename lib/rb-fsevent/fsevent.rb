class FSEvent
  attr_reader :path, :callback, :pipe
  
  def watch(path, &callback)
    @path     = path
    @callback = callback
  end
  
  def run
    launch_bin
    listen
  end
  
  def stop
    Process.kill("KILL", pipe.pid) if pipe
  end
  
private
  
  def bin_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin'))
  end
  
  def launch_bin
      @pipe = IO.popen("#{bin_path}/fsevent_watch #{path.shellescape}")
  end
  
  def listen
    while !pipe.eof?
      if line = pipe.readline
        modified_dir_paths = line.split(":").select { |dir| dir != "\n" }
        callback.call(modified_dir_paths)
      end
    end
  rescue Interrupt
    stop
  end
  
end