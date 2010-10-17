require 'ffi'

module CarbonCore
  extend FFI::Library
  ffi_lib '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Versions/Current/CarbonCore'
  
  attach_function :CFStringCreateWithCString, [:pointer, :string, :int], :pointer
  KCFStringEncodingUTF8 = 0x08000100
  attach_function :CFStringGetLength, [:pointer, :pointer, :int, :pointer, :pointer, :pointer], :int
  
  attach_function :CFArrayCreate, [:pointer, :pointer, :int, :pointer], :pointer
  
  attach_function :CFRunLoopRun, :CFRunLoopRun, [], :void
  attach_function :CFRunLoopGetCurrent, [], :pointer
  attach_variable :kCFRunLoopDefaultMode, :pointer
  
  callback :FSEventStreamCallback, [:pointer, :pointer, :int, :pointer, :pointer, :pointer], :void
  
  KFSEventStreamEventIdSinceNow = -1
  attach_function :FSEventStreamCreate, [:pointer, :FSEventStreamCallback, :pointer, :pointer, :long, :double, :int], :pointer
  attach_function :FSEventStreamScheduleWithRunLoop, [:pointer, :pointer, :pointer], :void
  attach_function :FSEventStreamStart, [:pointer], :void
  attach_function :FSEventStreamStop, [:pointer], :void
end

class FSEventStream
  KFSEventStreamEventFlagMustScanSubDirs = 0x1
  
  class StreamError < StandardError;
  end
  
  attr_accessor :stream
  
  def initialize(paths, latency, block)
    # Create array of paths to observe
    paths_ptr = FFI::MemoryPointer.new(:pointer)
    paths.each do |path|
      path_cfstring = CarbonCore.CFStringCreateWithCString(nil, path, CarbonCore::KCFStringEncodingUTF8)
      paths_ptr.write_pointer(path_cfstring)
    end
    paths_cfarray = CarbonCore.CFArrayCreate nil, paths_ptr, 1, nil
    
    # Create callback
    callback = lambda do |stream, client_callback_info, number_of_events, event_paths, event_flags, event_ids|
      if number_of_events > 0
        paths = event_paths.get_array_of_string(0, number_of_events)
        block.call(paths)
        # $stdout.puts paths.join(" ")
        # $stdout.flush
      end
    end
    
    @stream = CarbonCore.FSEventStreamCreate(nil, callback, nil, paths_cfarray, CarbonCore::KFSEventStreamEventIdSinceNow, latency, 0)
    
    CarbonCore.FSEventStreamScheduleWithRunLoop(stream, CarbonCore.CFRunLoopGetCurrent, CarbonCore.kCFRunLoopDefaultMode)
    CarbonCore.FSEventStreamStart(stream)
  end
  
  def run_loop
    CarbonCore.CFRunLoopRun
  end
  
  def stop
    CarbonCore.FSEventStreamStop(stream)
  end
end