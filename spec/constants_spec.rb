require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/constants'


describe "constants" do
  describe "defaults" do
    before(:each) do
    end
    it "should define constants" do
      Illuminati::BASECALLS_PATH.should == File.join('Data', 'Intensities', 'BaseCalls')
    end
  end
end
