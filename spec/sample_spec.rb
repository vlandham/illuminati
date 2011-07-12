
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_record'

describe Illuminati::Sample do
  before(:each) do
    @lims_data = {:flowcell => "123", :lane => "2", :genome => "mm9", :name => "name", :protocol => "eland_extended"}
    @sample = Illuminati::Sample.new
  end

  it "should add lims data" do
    @sample.add_lims_data(@lims_data)
    @sample.name.should == "name"
    @sample.lane.should == "2"
  end

  it "should clean names" do
    names = [["123", "123"], [" asd4+5", "asd4_5"], ["   34 RHO dig -  ", "34_RHO_dig_-"]]
    names.each do |raw_name, clean_name|
      @sample.name = raw_name
      @sample.clean_name.should == clean_name
    end
  end

  it "should have a valid id" do
    @sample.add_lims_data(@lims_data)
    @sample.id.should == @lims_data[:lane]
    @sample.barcode = "ACTAGC"
    @sample.barcode_type = :illumina
    @sample.id.should == "#{@lims_data[:lane]}_ACTAGC"
    @sample.barcode_type = :custom
    @sample.id.should == @lims_data[:lane]
  end

  it "should indicate if sample is control or not" do
    @sample.genome = "phix"
    @sample.control.should == "Y"
    @sample.genome = "phiX"
    @sample.control.should == "Y"
    @sample.genome = "mm9"
    @sample.control.should == "N"
    @sample.genome = "hg19"
    @sample.control.should == "N"
  end

  it "should deal with barcodes" do
    barcode = "ACATAG"
    @sample.barcode = barcode
    @sample.barcode_type = :illumina
    @sample.illumina_barcode.should == barcode
    @sample.custom_barcode.should == ""
    @sample.barcode_type = :custom
    @sample.illumina_barcode.should == ""
    @sample.custom_barcode.should == barcode
  end
end
