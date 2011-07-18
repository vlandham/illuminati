require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_record'

class FakePaths
  attr_accessor :base_dir, :unaligned_dir

  def initialize
    @base_dir = File.expand_path(File.dirname(__FILE__) + "/data")
    @unaligned_dir = File.join(@base_dir, 'Unaligned')
  end

  def to_h
    {}
  end
end

describe Illuminati::FlowcellRecord do
  describe "illumina indexed flowcell" do
    before(:each) do
      @valid_id = "639P5AAXX"
      @paths = FakePaths.new
      @valid_record = Illuminati::FlowcellRecord.find @valid_id, @paths
    end

    it "should have an id" do
      @valid_record.id.should == @valid_id
    end

    it "should have an lanes" do
      @valid_record.lanes.size.should == 8
      @valid_record.lanes[7].samples.size.should == 1
    end

    it "should output sample sheet data" do
      sample_sheet_filename = File.join(@paths.base_dir, "#{@valid_id}_SampleSheet.csv")
      File.exists?(sample_sheet_filename).should == true
      sample_sheet_example = File.open(sample_sheet_filename, 'r').read
      @valid_record.to_sample_sheet.should == sample_sheet_example
    end

    it "should convert to hash" do
      hash = @valid_record.to_h
      hash[:samples].size.should == 38
    end

    it "should not allow modifying of values through hash" do
      hash = @valid_record.to_h
      @valid_record.id.should == hash[:flowcell_id]
      hash[:flowcell_id] = "123"
      @valid_record.id.should_not == hash[:flowcell_id]
      @valid_record.lanes[0].samples[0].name.should == hash[:samples][0][:name]
      hash[:samples][0][:name] = "bad name"
      @valid_record.lanes[0].samples[0].name.should_not == hash[:samples][0][:name]
    end

    it "should convert to yaml" do
      yaml = @valid_record.to_yaml
      yaml.should_not == nil
    end

    it "should output config file" do
      config_filename = File.join(@paths.base_dir, "#{@valid_id}_config.txt")
      File.exists?(config_filename).should == true
      config_example = File.open(config_filename, 'r').read
      @valid_record.to_config_file.should == config_example
    end
  end

  describe "custom barcoded" do
    before(:each) do
      @valid_id = "639P5AAXX"
      @paths = FakePaths.new
      @paths.base_dir = File.join(@paths.base_dir, "custom")
      @valid_record = Illuminati::FlowcellRecord.find @valid_id, @paths
    end

    it "should output sample sheet data" do
      sample_sheet_filename = File.join(@paths.base_dir, "#{@valid_id}_SampleSheet.csv")
      File.exists?(sample_sheet_filename).should == true
      sample_sheet_example = File.open(sample_sheet_filename, 'r').read
      @valid_record.to_sample_sheet.should == sample_sheet_example
    end

    it "should " do
    end
  end
end
