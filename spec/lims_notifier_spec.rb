require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/lims_notifier'

class LNFakePaths < Illuminati::FlowcellPaths
  def initialize flowcell_id, testing = false
    super flowcell_id, testing
  end
  def base_dir
    @base_dir = File.expand_path(File.join(File.dirname(__FILE__), "data", "flowcell_123"))
    @base_dir
  end
end


describe Illuminati::LimsUploadView do
  before(:each) do
    @flowcell_id = "639KDAAXX"
    #@paths = LNFakePaths.new("123",true)
    @flowcell = Illuminati::FlowcellRecord.find(@flowcell_id)
    @view = Illuminati::LimsUploadView.new(@flowcell)
  end

  # NOTE - this test will only work as long as the flowcell is present on solexa
  # will not work on local machine
  it "should make report" do
    data = @view.to_json
    @view.upload_to_lims

    puts data.inspect
  end
end
