class FSEvent
  attr_reader :path, :latency, :callback, :pipe
  
  def watch(path, options = {}, &callback)
    @path     = path
    @latency  = options[:latency] || 0.5
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
    @pipe = IO.popen("#{bin_path}/rb-fsevent #{path} #{latency}")
  end
  
  def listen
    while !pipe.eof?
      if line = pipe.readline
        modified_dir_paths = line.split(" ")
        callback.call(modified_dir_paths)
      end
    end
  rescue Interrupt
    stop
  end
  
end