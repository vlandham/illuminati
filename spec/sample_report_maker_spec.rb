require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/sample_report_maker'

class SRFakePaths < Illuminati::FlowcellPaths
  def initialize flowcell_id, testing = false
    super flowcell_id, testing
  end
  def base_dir
    @base_dir = File.expand_path(File.join(File.dirname(__FILE__), "data", "flowcell_123"))
    @base_dir
  end
end


describe Illuminati::SampleReportMaker do
  before(:each) do
    @flowcell_id = "639KDAAXX"
    #@paths = SRFakePaths.new("123",true)
    @flowcell = Illuminati::FlowcellRecord.find(@flowcell_id)
  end

  # NOTE - this test will only work as long as the flowcell is present on solexa
  # will not work on local machine
  it "should make report" do
    results = Illuminati::SampleReportMaker::make @flowcell
    #File.open('testsers','w') do |file|
    #  file.puts results
    #end
    example_results = data("#{@flowcell.id}_Sample_Report.csv")
    results.should == example_results
  end
end
