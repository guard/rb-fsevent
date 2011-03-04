class FSEvent
  class << self
    class_eval <<-END
      def root_path
        "#{File.realpath(File.expand_path(File.join(File.dirname(__FILE__), '..', '..')))}"
      end
    END
    class_eval <<-END
      def watcher_path
        "#{File.join(FSEvent.root_path, 'bin', 'fsevent_watch')}"
      end
    END
  end

  attr_reader :paths, :callback

  def watch(watch_paths, &block)
    @paths    = watch_paths.kind_of?(Enumerable) ? watch_paths : [watch_paths]
    @callback = block
  end

  def run
    listen
  end

  def stop
    if pipe
      Process.kill("KILL", pipe.pid)
      pipe.close
    end
  rescue IOError
  ensure
    @pipe = false
  end

  def pipe
    @pipe ||= IO.popen("#{self.class.watcher_path} #{shellescaped_paths}")
  end

  private

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

  def shellescaped_paths
    @paths.map {|path| shellescape(path)}.join(' ')
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
