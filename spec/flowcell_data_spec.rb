
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_data'

describe Illuminati::FlowcellData do
  before(:each) do
    @data = Illuminati::FlowcellData.new("639P5AAXX", true)
  end

  it "should have a base dir" do
    @data.base_dir.should_not == nil
  end
end
