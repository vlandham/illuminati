require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_record'

class FakePaths
  attr_accessor :base_dir

  def initialize
    @base_dir = File.expand_path(File.dirname(__FILE__) + "/data")
  end
end


describe Illuminati::FlowcellRecord do
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
end
