require 'json'
require 'illuminati/external_data_base'

module Illuminati
  class ExternalDataLims < ExternalDataBase
    attr_reader :base_dir

    def initialize(base_dir = nil)
      @base_dir = base_dir
    end

    #
    # Internal interface to LIMS system. Unfortunately, this depends on an external
    # perl script for historical reasons.
    # perl script path: LIMS_SCRIPT_PATH
    #
    # == Returns:
    #
    def data_for flowcell_id
      script = ScriptPaths.lims_data
      lims_results = %x[#{script} #{flowcell_id}]
      lims_results.force_encoding("iso-8859-1")
      data = {"samples" => []}
      unless lims_results =~ /^[F|f]lowcell not found/
        data = JSON.parse(lims_results)
      end
      data
    end

    #
    # This method returns an array of hashes describing each sample in the flowcell
    # with the ID of flowcell_id.
    # Each hash contains the following keys:
    # {
    #   :lane => String name of lane (1 - 8),
    #   :name => Sample name.
    #   :lib_id => Sample Library ID
    #   :genome => Code for genome used for lane. Should correlate to folder name in genomes dir,
    #   :protocol => Should be either "eland_extended" or "eland_pair",
    #   :barcode_type => Should be :illumina, :custom, or :none
    #   :barcode => If :barcode_type is not :none, this provides the 6 sequence barcode
    #   :raw_barcode => Sequence to feed back to LIMS for reported barcode. No restriction on content.
    #   :order => Sample order
    #
    # }
    #
    def sample_data_for flowcell_id
      lims_data = data_for flowcell_id
      sample_datas = []
      # need to maintain protocol for control lane.
      previous_protocol = nil
      lims_data["samples"].each do |lims_sample_data|
        sample_data = {}

        sample_data[:lane] = lims_sample_data["laneID"]
        sample_data[:name] = lims_sample_data["sampleName"]
        sample_data[:genome] = lims_sample_data["genomeVersion"]
        sample_data[:protocol] = (lims_sample_data["readType"] == "Single Read") ? "eland_extended" : "eland_pair"
        sample_data[:barcode_type] = case(lims_sample_data["indexType"])
                                     when "ILL", "Illumina TruSeq", "Illumina"
                                       :illumina
                                     when "CUST"
                                       :custom
                                     when "BIOO", "BiooScientific", "BioScientific", "BiooSci_Fake", "BiooSci_Trimmed"
                                       :illumina
                                     when "Nextera", "Dual Custom"
                                       :illumina
                                     else
                                       :none
                                     end

        sample_data[:barcode_location] = case(lims_sample_data["locOfCustBarcode"])
                                         when "Illumina TruSeq Style"
                                           :illumina
                                         when "Nextera Duel Indexing"
                                           :dual
                                         when "Beginning of Insert"
                                           :custom
                                         else
                                           :custom
                                         end

        if lims_sample_data["indexSequences"] and !lims_sample_data["indexSequences"].empty?
          sample_data[:barcode] = lims_sample_data["indexSequences"].collect {|s| s.strip}.join("_")
          sample_data[:raw_barcode] = lims_sample_data["indexSequences"].collect {|s| s.strip}.join("_")
        else
          sample_data[:barcode] =  ""
          sample_data[:raw_barcode] =  ""
        end

        sample_data[:raw_barcode_type] = sample_data[:barcode_type]

        sample_data[:path] = lims_sample_data["resultsPath"]


        # prevent invalid barcodes
        if !is_valid_barcode? sample_data[:barcode]
          sample_data[:barcode] = ""
          sample_data[:barcode_type] = :none
        end

        sample_data[:lib_id] = lims_sample_data["libID"]
        sample_data[:order] = lims_sample_data["prnOrderNo"]


        if lims_sample_data["isControl"] == 1
          lane = lims_sample_data["laneID"] || "8"
          previous_protocol ||= "eland_extended"
          sample_data = sample_data_for_control_lane lane, previous_protocol
        else
          previous_protocol = sample_data[:protocol]
        end
        sample_datas << sample_data
      end
      sample_datas
    end

    def sample_data_for_control_lane lane, protocol
      sample_data = {}
      sample_data[:lane] = lane
      sample_data[:name] = "phiX"
      sample_data[:genome] = "phiX"
      sample_data[:protocol] = protocol
      sample_data[:barcode_type] = :none
      sample_data[:barcode] = ""
      sample_data[:path] = nil
      sample_data
    end

    def is_valid_barcode? sequence
      (sequence =~ /^[CAGTUcagtu_-]+$/) and (sequence.length > 5)
    end

    #
    # Returns distribution data for a given
    # flowcell id. Distribution data is an array of hashes. Each
    # hash has two keys:
    #
    #   :lane - the lane number to distribute.
    #   :path - the location of the project directory to distribute to.
    #
    # So if there are multiple lanes for one project directory, there will be
    # multiple entries in the distribution data for that project directory,
    # each with a different lane.
    #
    # If there is an error, an empty array should be returned. This will prevent
    # the rest of the system from dying, but will indicate to not distribute to
    # any project directory.
    #
    def distributions_for flowcell_id
      lims_data = data_for flowcell_id
      distributions = []
      lims_data["samples"].each do |lims_sample_data|
        unless distributions.collect {|d| d[:lane]}.include? lims_sample_data["laneID"]
          if lims_sample_data["resultsPath"]
            distribution = { :lane => lims_sample_data["laneID"], :path => lims_sample_data["resultsPath"] }
            distributions << distribution
          end
        end
      end
      distributions
    end
  end
end
