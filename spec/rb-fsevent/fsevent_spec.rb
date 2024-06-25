require 'spec_helper'

describe FSEvent do

  before(:each) do
    @results = []
    # lambdas enforce arity...
    callback = lambda do |paths|
      @results += paths
    end
    @fsevent = FSEvent.new
    @fsevent.watch @fixture_path.to_s, {:latency => 0.3, :no_defer => true}, &callback
  end

  it "shouldn't pass anything to watch when instantiated without a path" do
    fsevent = FSEvent.new
    expect(fsevent.paths).to be_nil
    expect(fsevent.callback).to be_nil
  end

  it "should pass path and block to watch when instantiated with them" do
    blk = proc { }
    fsevent = FSEvent.new(@fixture_path, &blk)
    expect(fsevent.paths).to eq([@fixture_path])
    expect(fsevent.callback).to eq(blk)
  end

  it "should have a watcher_path that resolves to an executable file" do
    expect(File.exist?(FSEvent.watcher_path)).to be true
    expect(File.executable?(FSEvent.watcher_path)).to be true
  end

  it "should catch new file" do
    file = @fixture_path.join("newfile.rb")
    File.delete file if File.exist? file
    run
    FileUtils.touch file
    stop
    File.delete file
    expect(@results).to eq([@fixture_path.to_s + '/'])
  end

  it "should catch file update" do
    file = @fixture_path.join("folder1/file1.txt")
    expect(File.exist?(file)).to be true
    run
    FileUtils.touch file
    stop
    expect(@results).to eq([@fixture_path.join("folder1/").to_s])
  end

  it "should catch files update" do
    file1 = @fixture_path.join("folder1/file1.txt")
    file2 = @fixture_path.join("folder1/folder2/file2.txt")
    expect(File.exist?(file1)).to be true
    expect(File.exist?(file2)).to be true
    run
    FileUtils.touch file1
    FileUtils.touch file2
    stop
    expect(@results).to eq([@fixture_path.join("folder1/").to_s, @fixture_path.join("folder1/folder2/").to_s])
  end

  def run
    sleep 1
    Thread.new { @fsevent.run }
    sleep 1
  end

  def stop
    sleep 1
    @fsevent.stop
  end

end
