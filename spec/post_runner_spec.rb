require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'post_runner'

class FakeFlowcell
  def initialize
  end

  def id
    '123'
  end

end

describe Illuminati::PostRunner do
  before(:each) do
    @flowcell = FakeFlowcell.new
    @runner = Illuminati::PostRunner.new @flowcell
    @runner.test = true
  end

  it "should have flowcell id" do
    @runner.flowcell.id.should == @flowcell.id
  end
end
