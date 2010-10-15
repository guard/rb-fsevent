require 'spec_helper'

describe FSEvent do
  
  before(:each) do
    @results = []
    @fsevent = FSEvent.new
    @fsevent.watch @fixture_path.to_s do |paths|
      @results += paths
    end
  end
  
  it "should catch new file" do
    file = @fixture_path.join("newfile.rb")
    File.exists?(file).should be_false
    run
    FileUtils.touch file
    stop
    File.delete file
    @results.should == [@fixture_path.to_s + '/']
  end
  
  it "should catch file update" do
    file = @fixture_path.join("folder1/file1.txt")
    File.exists?(file).should be_true
    run
    FileUtils.touch file
    stop
    @results.should == [@fixture_path.join("folder1/").to_s]
  end
  
  it "should catch files update" do
    file1 = @fixture_path.join("folder1/file1.txt")
    file2 = @fixture_path.join("folder1/folder2/file2.txt")
    File.exists?(file1).should be_true
    File.exists?(file2).should be_true
    run
    FileUtils.touch file1
    FileUtils.touch file2
    stop
    @results.should == [@fixture_path.join("folder1/").to_s, @fixture_path.join("folder1/folder2/").to_s]
  end
  
  def run
    Thread.new { @fsevent.run }
    sleep 2
  end
  
  def stop
    sleep 1
    @fsevent.stop
  end
  
end
