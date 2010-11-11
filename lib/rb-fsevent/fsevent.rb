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
    if pipe
      Process.kill("KILL", pipe.pid)
      pipe.close
    end
  rescue Interrupt, IOError
  end
  
private
  
  def bin_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'bin'))
  end
  
  def launch_bin
    @pipe = IO.popen("#{bin_path}/fsevent_watch #{shellescape(path)}")
  end
  
  def listen
    while !pipe.eof?
      if line = pipe.readline
        modified_dir_paths = line.split(":").select { |dir| dir != "\n" }
        callback.call(modified_dir_paths)
      end
    end
  rescue Interrupt, IOError
    stop
  end
  
  # for Ruby 1.8.6  support
  def shellescape(str)
    # An empty argument will be skipped, so return empty quotes.
    return "''" if str.empty?
    
    str = str.dup
    
    # Process as a single byte sequence because not all shell
    # implementations are multibyte aware.
    str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")
    
    # A LF cannot be escaped with a backslash because a backslash + LF
    # combo is regarded as line continuation and simply ignored.
    str.gsub!(/\n/, "'\n'")
    
    return str
  end
  
end