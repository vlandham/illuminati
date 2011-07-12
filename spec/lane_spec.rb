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
    sample_data = {:name => "abc", :lane => "4", :cycles => "40"}
    lane.add_samples sample_data, []
    lane.samples.size.should == 1
    lane.samples[0].name.should == sample_data[:name]
  end

  it "should add custom barcoded sample data" do
    lane = Illuminati::Lane.new(4)
    sample_data = {:name => "abc", :lane => "4", :cycles => "40"}
    multiplex_data = [{:lane => "4", :custom_barcode => "ACATGA", :name => "abc_1"}, {:lane => "4", :custom_barcode => "TGACTA", :name => "abc_2"}]
    lane.add_samples sample_data, multiplex_data
    lane.samples.size.should == 2
    lane.samples[0].name.should == multiplex_data[0][:name]
    lane.samples[-1].barcode.should == multiplex_data[-1][:custom_barcode]
    lane.barcode_type.should == :custom
  end
  it "should add multiplexed sample data" do
    lane = Illuminati::Lane.new(4)
    sample_data = {:name => "abc", :lane => "4", :cycles => "40"}
    multiplex_data = [{:lane => "4", :name => "abc_1", :illumina_barcode => "ACATGA"}, {:lane => "4", :name => "abc_2", :illumina_barcode => "TGACTA"}]
    lane.add_samples sample_data, multiplex_data 
    lane.samples.size.should == 2
    lane.samples[0].name.should == multiplex_data[0][:name]
    lane.samples[-1].barcode.should == multiplex_data[-1][:illumina_barcode]
    lane.barcode_type.should == :illumina
  end
end
