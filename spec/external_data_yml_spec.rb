require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'illuminati/external_data_yml'

describe Illuminati::ExternalDataYml do
  before(:each) do
    @external_data_file = File.expand_path(File.join(File.dirname(__FILE__), "data","external_data", "639KBAAXX_external_data.yml"))

    File.exists?(@external_data_file).should == true
    @lims = Illuminati::ExternalDataYml.new(@external_data_file)
  end

  it "should generate lane data" do
    good_lanes = [{:flowcell=>"639KBAAXX", :lane=>"1", :genome=>"mm9", :name=>"9.5dpc_HoxB1_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"2", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_M2Flag_IP",    :cycles=>"40",  :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"3", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_myc_IP", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"4", :genome=>"mm9", :name=>"HoxB1_3FMS_myc_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"5", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_IP", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"6", :genome=>"mm9", :name=>"HoxB1_HF_M2Flag_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"7", :genome=>"mm9", :name=>"Pbx_input", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"},
                  {:flowcell=>"639KBAAXX", :lane=>"8", :genome=>"phiX", :name=>"Phi X", :cycles=>"40", :protocol=>"eland_extended", :bases => "Y*"}]

    @lims.lane_data_for("639KBAAXX").should == good_lanes


  end

  it "should generate distribution data" do
    good_distributions = [{:lane=>1, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>2, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>3, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>4, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>5, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>6, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}, {:lane=>7, :path=>"/n/analysis/Krumlauf/bdk/Krumlauf-2011-06-23/639KBAAXX"}]

    @lims.distributions_for("639KBAAXX").should == good_distributions

  end
end
