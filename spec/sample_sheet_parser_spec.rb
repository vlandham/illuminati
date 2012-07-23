require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/sample_sheet_parser'

describe Illuminati::SampleSheetParser do
  before(:each) do
    id = "A103K"
    @sample_sheet_filename = File.expand_path(File.join(File.dirname(__FILE__), "data", id + "_SampleSheet.csv"))
    File.exists?(@sample_sheet_filename).should == true
  end

  it "should parse out samples" do
    data = Illuminati::SampleSheetParser.data_for(@sample_sheet_filename)
    data["samples"].length.should == 1
    data["samples"][0]["Sample_Name"].should == "L1401"
    data["samples"][0]["Sample_Number"].should == "1"
    data["header"]["Application"].should == "ChIP-Seq"
  end
end
