
require 'illuminati/external_data_base'
require 'illuminati/sample_multiplex'

module Illuminati
  #
  # Provides an interface for a very limit set of queries on the LIMS system.
  # Converts data from LIMS into a standard format that can be used in FlowcellRecord
  # to build up knowledge about a flowcell.
  # Current LIMS system works at the lane level, so data concerning lanes with multiple samples
  # is not captured. This is the reason SampleMulitplex.csv is used. to suppliment LIMS data.
  #
  class ExternalDataLims < ExternalDataBase
    attr_reader :base_dir
    # Specific data that is acquired from LIMS for a lane.
    LANE_DATA = [:flowcell, :lane, :genome, :name, :samples, :lab, :unknown, :cycles, :type, :protocol]
    LANE_DATA_CLEAN = [:flowcell, :lane, :genome, :name, :cycles, :protocol, :bases]

    # Input of organism in LIMS is unrestricted text. This is a mapping of all known names
    # that have been used in the LIMS in the past to the name we need for alignment.
    # To generate this mapping we queried the current LIMS directly to find all unique organism
    # names used.
    CONVERSIONS = {
      "Drosophila_melanogaster.BDGP5.4.54" => [/.*BDGP5.*/],
      "ce6" => [/ce6/],
      "dp3" => [/dp3/],
      "droSim1" => [/.*simulans.*/],
      "droAna2" => [/.*ananassae.*/],
      "mm9" => [/.*mm9.*/, /.*musculus.*/],
      "sacCer2" => [/.*sac[C|c]er2.*/, /.*[C|c]erevisiae.*/], 
      "hg19" => [/.*[H|h]uman.*/,/.*hg19.*/,/.*[S|s]apien.*/],
      "phiX" => [/.*phiX.*/, /.*phix.*/],
      "dm3" => [/.*dm3.*/, /.*[D|d]rosophila.*/],
      "pombe_9-2010" => [/.*[P|p]ombe.*/],
      "smed" => [/.*[F|f]latworm.*/, /.*[S|s]med.*/, /.*[S|s]chmidtea.*/]
    }

    def initialize(base_dir = nil)
      @base_dir = base_dir
    end

    #
    # Internal interface to LIMS system. Unfortunately, this depends on an external
    # perl script for historical reasons.
    #
    # == Parameters:
    # command::
    #   specific query to perform on LIMS, through perl script.
    #
    # flowcell_id::
    #   Flowcell id of flowcell we want information on.
    #
    # == Returns:
    # Array of raw row data. Each element in array is an array of values from LIMS
    # that have been split using the tab character. This is how the output of the
    # LIMS and the perl script look, so we will just use it as is.
    #
    def query command, flowcell_id
      query_script = ScriptPaths.lims_script
      query_results = %x[perl #{query_script} #{command} #{flowcell_id}]
      query_results.force_encoding("iso-8859-1")
      rows = query_results.split("\n")
      split_rows = rows.collect {|row| row.split("\t")}
      split_rows
    end

    #
    # This is the main interface between the LIMSAdapter and other classes.
    # Provides an array of hashes containing data for each lane found
    # for a given flowcell id.
    #
    # lane data is cleaned to translate the LIMS output into a unified
    # format that can be used in the rest of the application.
    #
    # == Parameters:
    # flowcell_id::
    #   Flowcell ID of the flowcell we want data from.
    #
    # == Returns:
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
      raw_lanes = query("fc_lane_library_samples", flowcell_id)
      lanes = Array.new
      raw_lanes.each do |raw_lane|
        lane_data = Hash.new
        LANE_DATA.each_with_index do |header, index|
          lane_data[header] = raw_lane[index]
        end
        lanes << clean_lane(lane_data)
      end
      lanes
      samples = sample_data_from_lanes(lanes)
    end

    #
    # Converts lane data from LIMS into sample data
    # that is necessary for flowcell records.
    #
    # It does this by combining the LIMS lane data with
    # data from the SampleMultiplex file, if present.
    # If not present, it will add the fields not found
    # in the current lims to the lane data and use that.
    #
    # Additional fields added by sample_data_from_lanes:
    #   :barcode
    #   :barcode_type
    #   :name (modified if found in the SampleMultiplex file)
    #
    def sample_data_from_lanes lanes
      samples = []
      multiplex_data = SampleMultiplex.find(@base_dir)
      seen_lanes = []
      lanes.each do |lims_lane|
        lane_number = lims_lane[:lane].to_i
        if !seen_lanes.include? lane_number
          seen_lanes << lane_number
          samples << combine_lane_and_multiplex_data(lims_lane, multiplex_data)
        end
      end
      samples.flatten!
      samples.sort! {|x,y| x[:lane].to_i <=> y[:lane].to_i}
      samples
    end

    #
    # Performs actual addition of the missing attributes for the sample data
    # fields added:
    #   :barcode_type
    #   :barcode
    #   :name
    #
    def combine_lane_and_multiplex_data lane_data, multiplex_data
      lane_multiplex_data = multiplex_data.select {|data| data[:lane].to_i == lane_data[:lane].to_i}
      samples = []
      if !lane_multiplex_data.empty?
        #lane_multiplex_data.sort! {|x,y| y[:name] <=> x[:name]}
        lane_multiplex_data.each do |multiplex_data|
          barcode_type, barcode = barcode_of(multiplex_data)
          sample = lane_data.clone
          sample[:barcode_type] = barcode_type
          sample[:barcode] = barcode
          sample[:name] = multiplex_data[:name] if multiplex_data[:name]
          samples << sample
        end
      else
          sample = lane_data.clone
          sample[:barcode_type] = :none
          sample[:barcode] = ""
          samples << sample
      end
      samples
    end

    #
    # Given a multiplex hash, it returns the barcode and
    # barcode type in the hash.
    # Raises error if both illumina and custom barcodes are present
    #
    def barcode_of multiplex_data
      if multiplex_data[:illumina_barcode] and multiplex_data[:custom_barcode]
        puts "ERROR: multiplex data has both illumina and custom barcodes"
        puts "       illumina barcode:#{multiplex_data[:illumina_barcode]}."
        puts "       custom barcode  :#{multiplex_data[:custom_barcode]}."
        raise "too many barcodes"
      elsif multiplex_data[:illumina_barcode]
        return :illumina, multiplex_data[:illumina_barcode]
      elsif multiplex_data[:custom_barcode]
        return :custom, multiplex_data[:custom_barcode]
      else
        return :none, ""
      end
    end

    def add_lanes lims_lane_data, multiplex_data
      seen_lanes = []
      lims_lane_data.each do |lims_lane|
        lane_number = lims_lane[:lane].to_i
        if !seen_lanes.include? lane_number
          lane_multiplex_data = multiplex_data.select {|data| data[:lane].to_i == lane_number}
          lane = Lane.new(lane_number)
          lane.add_samples(lims_lane, lane_multiplex_data)
          self.lanes << lane
          seen_lanes << lane_number
        end
      end
      self.lanes.sort! {|x,y| x.number <=> y.number}
    end

    #
    # Helper method to fix up components of the lane hash before returning
    # it from lanes method.
    #
    # == Parameters:
    # lane_data::
    #   Single hash of lane data from LIMS.
    #
    # == Returns:
    # Same hash with contents ready to be used external fo the adapter.
    #
    def clean_lane lane_data
      lane_data[:genome] = translate_organism(lane_data[:genome])
      lane_data[:protocol] = translate_protocol(lane_data[:protocol])
      lane_data[:bases] = get_bases(lane_data[:protocol])
      clean_lane_data = {}
      LANE_DATA_CLEAN.each do |clean_header|
        clean_lane_data[clean_header] = lane_data[clean_header]
      end
      clean_lane_data
    end

    #
    # Cleans the protocol field from the LIMS system so that it only can
    # contain "eland_pair" or "eland_extended"
    #
    def translate_protocol raw_protocol
      raw_protocol.downcase =~ /.*pair.*/ ? "eland_pair" : "eland_extended"
    end

    #
    # Returns string representing the bases to read to be used in config.txt
    # file. Deals with paired vs single-ended reads.
    #
    def get_bases protocol
      protocol == "eland_pair" ? "Y*,Y*" : "Y*"
    end

    #
    # Uses look up table to convert organism name from LIMS into name
    # that can be used to specify reference genome in Illuminati.
    # Prints error message if conversion cannot be done.
    #
    def translate_organism raw_organism
      new_type = raw_organism
      matched = false
      CONVERSIONS.each do |valid_name, matches|
        matches.each do |match|
          if new_type =~ match
            new_type = valid_name
            matched = true
            break
          end
        end
        break if matched
      end
      puts "ERROR: #{new_type} not in conversions table" unless matched
      new_type
    end

    #
    # Performs the LIMS query using the external perl script.
    # Returns raw results broken up by tabs into an array.
    #
    def distribution_query flowcell_id
      query_results = %x[perl #{SCRIPT_PATH}/ngsquery.pl fc_postRunArgs #{flowcell_id}]
      query_results.force_encoding("iso-8859-1")
      query_results.split("\t")
    end

    #
    # Main interface. Returns distribution data for a given
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
      raw_data = distribution_query flowcell_id
      distribution_data = []

      if raw_data.size >= 2
        distribution_paths = raw_data[0].split(":")
        distribution_lane_sets = raw_data[1].split(":")
        distribution_lane_sets.each_with_index do |lane_set, index|
          lanes = lane_set.split(",")
          lanes.each do |lane|
            dist = {:lane => lane.to_i, :path => distribution_paths[index]}
            distribution_data << dist
          end
        end
      end
      distribution_data
    end
  end
end
