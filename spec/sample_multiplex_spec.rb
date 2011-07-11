require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/sample_multiplex'


describe Illuminati::SampleMultiplex do
  before(:each) do
    @base_path = File.expand_path(File.dirname(__FILE__) + "/data")
    @multiplex = Illuminati::SampleMultiplex
  end

  it "should find a mutliplex file in base path" do
    out = capture(:stdout){@multiplex.find_file(@base_path).should_not == nil}
  end

  it "should not find multiplex file in invalid location" do
    out = capture(:stdout) {@multiplex.find_file("/tmp").should == nil}
  end

  it "should parse multiplex csv file" do
    capture(:stdout) do
      data = @multiplex.find(@base_path)
      data[0][:lane].should == "1"
      data[-1][:lane].should == "8"
      data.size.should == 38
    end
  end
end
