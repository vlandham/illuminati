require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/tab_file_parser'


describe Illuminati::TabFileParser do
  before(:each) do
    @parser = Illuminati::TabFileParser.new
  end

  it "should parse tabbed input into array of hashes" do
    input = "title1\ttitle2\ttitle3\n1\t2\t3\n11\t22\t33\n"
    data = @parser.parse_tabbed_string(input)
    data.size.should == 2
    data[0]["title1"].should == "1"
    data[1]["title3"].should == "33"
  end

  it "should handle different number of columns" do
    input = "title1\ttitle2\ttitle3\tmissing\n1\t2\t3\n11\t22\t33\tm1\n"
    data = @parser.parse_tabbed_string(input)
    data.size.should == 2
    data[0]["title1"].should == "1"
    data[1]["title3"].should == "33"
    data[0]["missing"].should == nil
    data[1]["missing"].should == "m1"
  end

  it "should read fastx barcode splitter output" do
    fastx_barcode_out_filename = File.join(File.dirname(__FILE__), "data", "custom_barcode_6.txt.out")
    File.exists?(fastx_barcode_out_filename).should == true

    data = @parser.parse(fastx_barcode_out_filename)
    data.size.should == 5
    data[0]["Barcode"].should == "GATCGT"
    data[-1]["Location"].should == nil
  end
end
