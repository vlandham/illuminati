
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/lims_adapter'

describe Illuminati::LimsAdapter do
  before(:each) do
    @lims = Illuminati::LimsAdapter
  end

  it "should translate organisms" do
    orgs = [["Dro So BDGP5", "Drosophila_melanogaster.BDGP5.4.54"], ["Human", "hg19"]]
    orgs.each do |input_name, translation|
      @lims.translate_organism(input_name).should == translation
    end
  end

  it "should produce array of hashes with lane info" do
    good_lanes = [{:flowcell=>"639KBAAXX", :lane=>"1", :genome=>"mm9", :name=>"9.5dpc_HoxB1_input", :samples=>"9.5dpc_HoxB1_input", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"2", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_M2Flag_IP", :samples=>"HoxB1_3FMS_myc_M2Flag_IP", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"}, 
                  {:flowcell=>"639KBAAXX", :lane=>"3", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_myc_IP", :samples=>"HoxB1_3FMS_myc_myc_IP", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"}, 
                  {:flowcell=>"639KBAAXX", :lane=>"4", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_input", :samples=>"HoxB1_3FMS_myc_input", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"5", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_IP", :samples=>"HoxB1_HF_M2Flag_IP", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"6", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_input", :samples=>"HoxB1_HF_M2Flag_input", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"7", :genome=>"mm9", :name=>"Pbx_input", :samples=>"Pbx_input", :lab=>"Krumlauf", :unknown=>"1", :cycles=>"40", :type=>"CHIP-SEQ", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"8", :genome=>"phiX", :name=>"Phi X", :samples=>"PhiX", :lab=>"Molecular_Biology", :unknown=>"1", :cycles=>"40", :type=>"OTHER", :protocol=>"eland_extended", :bases => "Y*"}]
    lanes = @lims.lanes "639KBAAXX"
    lanes.should == good_lanes
  end

end
