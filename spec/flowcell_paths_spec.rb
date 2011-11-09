
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/flowcell_paths'

describe Illuminati::FlowcellPaths do
  before(:each) do
    @data = Illuminati::FlowcellPaths.new("6323AAAXX", true)
  end

  it "should have a base dir" do
    @data.base_dir.should_not == nil
  end
end
