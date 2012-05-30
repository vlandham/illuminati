require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/constants'

describe 'illuminati scripts' do

  it "should have fastqc.pl present" do
    File.exists?(Illuminati::ScriptPaths.fastqc_script).should == true
    results = %x[#{Illuminati::ScriptPaths.fastqc_script} -h]
    results.should match(/^usage/)
  end

  it "should have the new lims query script present" do
    File.exists?(Illuminati::ScriptPaths.lims_data).should == true
  end
end
