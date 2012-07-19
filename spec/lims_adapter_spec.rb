
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/external_data_lims'

describe Illuminati::ExternalDataLims do
  before(:each) do
    @lims = Illuminati::ExternalDataLims.new
  end

  # it "should translate organisms" do
  #   orgs = [["Dro So BDGP5", "Drosophila_melanogaster.BDGP5.4.54"], ["Human", "hg19"]]
  #   orgs.each do |input_name, translation|
  #     @lims.translate_organism(input_name).should == translation
  #   end
  # end

  it "should produce array of hashes with lane info" do
    good_lanes = [{:flowcell=>"639KBAAXX", :lane=>"1", :genome=>"mm9", :name=>"9.5dpc_HoxB1_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"2", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_M2Flag_IP",    :cycles=>"40",  :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"3", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_myc_IP", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"4", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"5", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_IP", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"6", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"7", :genome=>"mm9", :name=>"Pbx_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""},
                  {:flowcell=>"639KBAAXX", :lane=>"8", :genome=>"phiX", :name=>"Phi X", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*", :barcode_type => :none, :barcode => ""}]
    lanes = @lims.sample_data_for "639KBAAXX"
    lanes.should == good_lanes
  end

  it "should produce array of hashes for distribution data" do
    good_distributions = [{:lane=>1, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>2, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>3, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>4, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>5, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>6, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>7, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}]
    distributions = @lims.distributions_for "639KBAAXX"
    distributions.should == good_distributions
  end

end
