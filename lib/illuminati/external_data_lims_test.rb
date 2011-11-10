require 'json'
require 'illuminati/external_data_yml'

module Illuminati
  class ExternalDataLimsTest < ExternalDataYml

    TEST_FLOWCELLS_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec", "flowcells"))
    attr_reader :base_dir

    def initialize(base_dir = nil)
      @base_dir = base_dir
      super(nil)
    end

    def set_filename flowcell_id
      self.filename = File.join(TEST_FLOWCELLS_DIR, flowcell_id, "lims_data.yml")
    end

    #
    # Internal interface to LIMS system. Unfortunately, this depends on an external
    # perl script for historical reasons.
    # perl script path: LIMS_SCRIPT_PATH
    #
    # == Returns:
    #
    def data_for flowcell_id
      set_filename flowcell_id
      super(flowcell_id)
    end

    #
    # This method returns an array of hashes describing each sample in the flowcell
    # with the ID of flowcell_id.
    # Each hash contains the following keys:
    # {
    #   :lane => String name of lane (1 - 8),
    #   :name => Sample name.
    #   :genome => Code for genome used for lane. Should correlate to folder name in genomes dir,
    #   :protocol => Should be either "eland_extended" or "eland_pair",
    #   :barcode_type => Should be :illumina, :custom, or :none
    #   :barcode => If :barcode_type is not :none, this provides the 6 sequence barcode
    # }
    #
    def sample_data_for flowcell_id
      set_filename flowcell_id
      super(flowcell_id)
    end
  end
end
