# -*- encoding: utf-8 -*-

class FSEvent
  class << self
    class_eval <<-END
      def root_path
        "#{File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))}"
      end
    END
    class_eval <<-END
      def watcher_path
        "#{File.join(FSEvent.root_path, 'bin', 'fsevent_watch')}"
      end
    END
  end

  attr_reader :paths, :callback

  def initialize args = nil, &block
    watch(args, &block) unless args.nil?
  end

  def watch(watch_paths, options=nil, &block)
    @paths      = watch_paths.kind_of?(Array) ? watch_paths : [watch_paths]
    @callback   = block

    if options.kind_of?(Hash)
      @options  = parse_options(options)
    elsif options.kind_of?(Array)
      @options  = options
    else
      @options  = []
    end
  end

  def run
    @pipe    = open_pipe
    @running = true

    # please note the use of IO::select() here, as it is used specifically to
    # preserve correct signal handling behavior in ruby 1.8.
    while @running && IO::select([@pipe], nil, nil, nil)
      if line = @pipe.readline
        modified_dir_paths = line.split(':').select { |dir| dir != "\n" }
        callback.call(modified_dir_paths)
      end
    end
  rescue Interrupt, IOError, Errno::EBADF
  ensure
    stop
  end

  def stop
    unless @pipe.nil?
      Process.kill('KILL', @pipe.pid) if process_running?(@pipe.pid)
      @pipe.close
    end
  rescue IOError
  ensure
    @running = false
  end

  def process_running?(pid)
    begin
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end

  if RUBY_VERSION < '1.9'
    def open_pipe
      IO.popen("'#{self.class.watcher_path}' #{options_string} #{shellescaped_paths}")
    end

    private

    def options_string
      @options.join(' ')
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
  else
    def open_pipe
      pid = IO.popen([self.class.watcher_path] + @options + @paths)
    ensure
      generate_assassin_for(pid)
    end
  end

  private

  def parse_options(options={})
    opts = []
    opts.concat(['--since-when', options[:since_when]]) if options[:since_when]
    opts.concat(['--latency', options[:latency]]) if options[:latency]
    opts.push('--no-defer') if options[:no_defer]
    opts.push('--watch-root') if options[:watch_root]
    opts.push('--file-events') if options[:file_events]
    # ruby 1.9's IO.popen(array-of-stuff) syntax requires all items to be strings
    opts.map {|opt| "#{opt}"}
  end

  unless RUBY_VERSION < '1.9'
    require 'securerandom'
    require 'tmpdir'

    def generate_assassin_for(child_pid, options = {})
      path = File.join(Dir.tmpdir, "assassin-#{ child_pid }-#{ SecureRandom.uuid }.rb")
      script = assassin_script_for(child_pid, options)
      IO.binwrite(path, script)
      pid = Process.spawn "ruby #{ path }"
      Process.detach(pid)
      [pid, path]
    end

    def assassin_script_for(child_pid, options = {})
      parent_pid = Process.pid

      assassin = <<-__
        parent_pid = #{ parent_pid }
        child_pid = #{ child_pid }

        m = 24*60*60
        n = 4242
        
        m.times do
          begin
            Process.kill(0, parent_pid)
          rescue Object => e
            if e.is_a?(Errno::ESRCH)
              n.times do
                begin
                  Process.kill(15, child_pid) rescue nil
                  sleep(rand + rand)
                  Process.kill(9, child_pid) rescue nil
                  sleep(rand + rand)
                  Process.kill(0, child_pid)
                rescue Errno::ESRCH
                  break
                end
              end
            end

            exit
          end

          sleep(1)
        end
      __
    end
  end
end
