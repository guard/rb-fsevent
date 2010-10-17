class FSEvent
  attr_reader :path, :latency, :callback, :stream
  
  def watch(path, options = {}, &callback)
    @path     = path
    @latency  = options[:latency] || 0.5
    @callback = callback
  end
  
  def run
    @stream = FSEventStream.new([path], latency, callback)
    @stream.run_loop
  rescue Interrupt
    stop
  end
  
  def stop
    stream.stop
  end
  
end