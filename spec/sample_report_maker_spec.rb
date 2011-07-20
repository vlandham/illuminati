require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/sample_report_maker'


describe Illuminati::SampleReportMaker do
  before(:each) do
  end

  # NOTE - this test will only work as long as the flowcell is present on solexa
  # will not work on local machine
  it "should make report" do
    flowcell_id = "639KDAAXX"
    results = Illuminati::SampleReportMaker::make flowcell_id
    example_results = data("#{flowcell_id}_Sample_Report.csv")
    results.should == example_results
  end
end
