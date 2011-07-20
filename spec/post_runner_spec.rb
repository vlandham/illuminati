require 'yaml'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'post_runner'

class FakeFlowcell
  attr_accessor :base_dir, :unaligned_dir, :id, :qc_dir, :unaligned_stats_dir, :aligned_dir, :aligned_stats_dir, :fastqc_dir

  def initialize
    @base_dir = File.expand_path(File.join(File.dirname(__FILE__), "data", "flowcell_123"))
    @unaligned_dir = File.join(@base_dir, 'Unaligned')
    @id = '123'
    @qc_dir = File.expand_path(File.join(File.dirname(__FILE__), "sandbox", "flowcell_123"))
    @unaligned_stats_dir = File.join(@unaligned_dir, 'Basecall_Stats_123')
    @aligned_dir = File.join(@base_dir, 'Aligned')
    @aligned_stats_dir = File.join(@aligned_dir, "Project_123", 'Summary_Stats_FC')
    @fastqc_dir = File.join(@unaligned_dir, 'filter','fastqc')
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
      @all_data = YAML.load(data("illumina_fastq_files.yaml"))
      @file_data = @all_data[:file_data]
      @group_data = @all_data[:group_data]
      @starting_path = @all_data[:starting_path]
      @output_path = @all_data[:ending_path]
    end

    it "should group files properly" do
      results = @runner.group_files(@file_data, @starting_path, @output_path)
      results.size.should == 5
      @group_data.size.should == results.size
      results.each_with_index do |result,index|
        [:group_name, :path, :filter_path, :sample_name, :lane].each do |key|
          result[key].should == @group_data[index][key]
        end
        result[:files].size.should == @group_data[index][:files_size]
      end
    end
  end

  describe "get_file_data" do
    before(:each) do
      @file_data = YAML.load(data("illumina_fastq_files.yaml"))[:file_data]
    end

    it "should match file names" do
      @file_data.each do |data|
        results = @runner.get_file_data(data[:path])
        results.size.should == 1
        result = results[0]
        result[:name].should == data[:name]
        result[:name].include?("/").should == false
        result[:name].include?("fastq.gz").should == true
        result[:path].should == data[:path]
        result[:barcode].should == data[:barcode]
        result[:lane].should == data[:lane]
        result[:read].should == data[:read]
        result[:sample_name].should == data[:sample_name]
      end
    end
  end

  describe "get_file_data" do
    before(:each) do
      @all_data = YAML.load(data("illumina_fastq_files.yaml"))
    end
  end

  describe "distribute_to_qcdata" do
    it "should say its distributing files" do
      out = capture(:stdout) {@runner.distribute_to_qcdata}
      qcdata_out = fixture('distribute_qcdata')
      out.should == qcdata_out
    end
  end

  describe "run" do
    it "should say its running" do
      #out = capture(:stdout) {@runner.run}
      #out.should == nil
    end
  end
end
