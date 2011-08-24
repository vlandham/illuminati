require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/external_data_lims_new'

describe Illuminati::ExternalDataLimsNew do
  before(:each) do
    @lims = Illuminati::ExternalDataLimsNew.new
  end

  it "should have data for flowcell" do
    flowcell = "64E52AAXX"
    data = @lims.data_for flowcell
    data.kind_of?(Hash).should == true
    data["samples"].size.should == 21
    puts data
  end
end
