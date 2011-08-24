require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/casava_output_parser'

class FakeSample
  attr_accessor :lane, :barcode_string
  def initialize(lane, barcode)
    self.lane = lane
    self.barcode_string = barcode
  end
  def id
    "#{lane}_#{barcode_string}"
  end
end

describe Illuminati::CasavaOutputParser do
  before(:each) do
    id = "BB027YABXX"
    base_dir = File.expand_path(File.join(File.dirname(__FILE__), "data", id))
    demultiplex_filename = File.join(base_dir, "Demultiplex_Stats.htm")
    sample_summary_filename = File.join(base_dir, "Sample_Summary.htm")
    File.exists?(demultiplex_filename).should == true
    File.exists?(sample_summary_filename).should == true
    @casava_output = Illuminati::CasavaOutputParser.new(demultiplex_filename,sample_summary_filename)
  end

  it "should parse out samples" do
    sample = FakeSample.new("2", "CGATGT")
    data = @casava_output.data_for(sample,1)
    data["# Reads"].should == 69225794
    #puts data
  end
end
