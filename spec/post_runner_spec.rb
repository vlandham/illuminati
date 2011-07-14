require 'yaml'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'post_runner'

class FakeFlowcell
  attr_accessor :base_dir, :unaligned_dir, :id

  def initialize
    @base_dir = File.expand_path(File.dirname(__FILE__) + "/data")
    @unaligned_dir = File.join(@base_dir, 'Unaligned')
    @id = '123'
  end
end

describe Illuminati::PostRunner do
  before(:each) do
    @flowcell = FakeFlowcell.new
    @runner = Illuminati::PostRunner.new @flowcell
    @runner.test = true
  end

  it "should have flowcell id" do
    @runner.flowcell.id.should == @flowcell.id
  end

  it "should output log data" do
    message = "log this"
    out = capture(:stdout) {@runner.log message}
    out.chomp.should == message
  end

  it "should log executed commands" do
    command = "ls"
    out = capture(:stdout) {@runner.execute command}
    out.chomp.should == command
  end

  it "should check if file is missing" do
    files = Dir.glob(@flowcell.base_dir + "/*")
    files.size.should_not == 0
    out = capture(:stdout) {@runner.check_exists(files)}
    out.empty?.should == true
    @runner.check_exists(files).should == true
    @runner.check_exists(files[0]).should == true
  end

  describe "group_files" do
    before(:each) do
    end
  end

  describe "get_data" do
    before(:each) do
      @files = Array[YAML.load(data("illumina_fastq_files.yaml"))]


    end
  end
end
