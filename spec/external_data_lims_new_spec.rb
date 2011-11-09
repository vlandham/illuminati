require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/external_data_lims_new'

describe Illuminati::ExternalDataLimsNew do
  before(:each) do
    @lims = Illuminati::ExternalDataLimsNew.new
  end

  # TODO: This spec is using data from the test installation of the
  # new lims system.
  # It should be rewritten to use local data, or at least permanant lims data.

  it "should have data for flowcell" do
    flowcell = "6323AAAXX"
    data = @lims.data_for flowcell
    data.kind_of?(Hash).should == true
    data["samples"].size.should == 9
    #puts data
  end

  it "should fill in control data for control lane" do
    flowcell = "6323AAAXX"
    sample_data = @lims.sample_data_for flowcell
    sample_data[-1][:lane].should == "8"
    sample_data[-1][:genome].should == "phiX"
    sample_data[-2][:genome].should_not == "phiX"
    sample_data[-1][:protocol].should == "eland_extended"
  end

  it "should have sample data for all lanes" do
    flowcell = "6323AAAXX"
    sample_data = @lims.sample_data_for flowcell
    lanes = sample_data.collect {|s| s[:lane]}
    lanes.include?(nil).should == false
    [1,2,3,4,5,6,8].each {|i| lanes.include?(i.to_s).should == true}
    [0,9,-1,100].each {|ni| lanes.include?(ni.to_s).should == false}
  end
end
