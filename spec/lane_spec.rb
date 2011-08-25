require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_record'

describe Illuminati::Lane do
  before(:each) do
  end

  it "should have a number" do
    lane = Illuminati::Lane.new(4)
    lane.number.should == 4
  end

  it "should add sample data" do
    lane = Illuminati::Lane.new(4)
    sample_data = [{:name => "abc", :lane => "4", :cycles => "40"}]
    lane.add_samples sample_data
    lane.samples.size.should == 1
    lane.samples[0].name.should == sample_data[0][:name]
  end

  it "should add custom barcoded sample data" do
    lane = Illuminati::Lane.new(4)
    sample_data = [{:name => "abc_1", :lane => "4", :cycles => "40", :barcode => "ACATGA", :barcode_type => :custom},{:name => "abc_2", :lane => "4", :barcode => "TGACTA", :barcode_type => :custom}]
    lane.add_samples sample_data
    lane.samples.size.should == 2
    lane.samples[0].name.should == sample_data[0][:name]
    lane.samples[-1].barcode.should == sample_data[-1][:barcode]
    lane.barcode_type.should == :custom
  end

  it "should add multiplexed sample data" do
    lane = Illuminati::Lane.new(4)
    sample_data = [{:name => "abc_1", :lane => "4", :cycles => "40", :barcode => "ACATGA", :barcode_type => :illumina}, {:name => "abc_2", :lane => "4", :cycles => "40", :barcode => "TGACTA", :barcode_type => :illumina}]
    lane.add_samples sample_data
    lane.samples.size.should == 2
    lane.samples[0].name.should == sample_data[0][:name]
    lane.samples[-1].barcode.should == sample_data[-1][:barcode]
    lane.barcode_type.should == :illumina
  end
end
