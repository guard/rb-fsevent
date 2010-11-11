# Workaround to make Rubygems believe it builds a native gem
require 'mkmf'
create_makefile('none')

if `uname -s`.chomp != 'Darwin'
  puts "Warning! Only Darwin (Mac OS X) systems are supported, nothing will be compiled"
else
  gem_root      = File.expand_path(File.join('..'))
  darwin_verion = `uname -r`.to_i
  sdk_verion    = { 9 => '10.5', 10 => '10.6', 11 => '10.7' }[darwin_verion]
  
  raise "Only Darwin systems greather than 8 (Mac OS X 10.5+) are supported" unless sdk_verion
  
  # Compile the actual fsevent_watch binary
  system "mkdir -p #{File.join(gem_root, 'bin')}"
  system "CFLAGS='-isysroot /Developer/SDKs/MacOSX#{sdk_verion}.sdk -mmacosx-version-min=#{sdk_verion}' /usr/bin/gcc -framework CoreServices -o '#{gem_root}/bin/fsevent_watch' fsevent/fsevent_watch.c"
  
  unless File.executable?("#{gem_root}/bin/fsevent_watch")
    raise "Compilation of fsevent_watch failed (see README)"
  end
end
