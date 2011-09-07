require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/constants'


describe "constants" do
  describe "defaults" do
    before(:each) do
    end
    it "should define constants" do
      Illuminati::CASAVA_PATH.should == '/home/solexa/CASAVA_1.8.1/bin'
    end
  end
end
