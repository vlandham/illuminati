require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/custom_barcode_file_maker'
require 'illuminati/sample_multiplex'
class FakePathsBarcode
  attr_accessor :base_dir, :unaligned_dir

  def initialize
    @base_dir = File.expand_path(File.dirname(__FILE__) + "/data/custom")
    @out_dir = File.expand_path(File.dirname(__FILE__) + "/sandbox")
    @unaligned_dir = File.join(@base_dir, 'Unaligned')
  end

  def custom_barcode_path lane
    File.join(@out_dir, "barcodes_#{lane}.txt")
  end

  def to_h
    {}
  end
end

describe Illuminati::CustomBarcodeFileMaker do
  before(:each) do
    @paths = FakePathsBarcode.new
    @external_data = Illuminati::ExternalDataYml.new(File.expand_path(File.dirname(__FILE__) + "/data/custom/external/639P5AAXX_external_data.yml"))
    @flowcell = Illuminati::FlowcellRecord.find("639P5AAXX", @paths, @external_data)
  end

  it "should create barcode files" do
    output = Illuminati::CustomBarcodeFileMaker.make(@flowcell)
    output.should == [1]
    output.each do |lane|
      path = @paths.custom_barcode_path(lane)
      File.exists?(path).should == true
      example_file = File.open(@paths.base_dir + "/barcodes_#{lane}.txt",'r').read
      barcode_file = File.open(path, 'r').read
      barcode_file.should == example_file
    end
  end
end
