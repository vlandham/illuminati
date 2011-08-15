
require 'illuminati/external_data_base'

module Illuminati
  #
  # Provides an interface for a very limit set of queries on the LIMS system.
  # Converts data from LIMS into a standard format that can be used in FlowcellRecord
  # to build up knowledge about a flowcell.
  # Current LIMS system works at the lane level, so data concerning lanes with multiple samples
  # is not captured. This is the reason SampleMulitplex.csv is used. to suppliment LIMS data.
  #
  class ExternalDataLims < ExternalDataBase
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
      "pombe_9-2010" => [/.*[P|p]ombe.*/]
    }

    def initialize
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
      query_results = %x[perl #{SCRIPT_PATH}/ngsquery.pl #{command} #{flowcell_id}]
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
    # Array of hashes. Each hash has keys listed in the LANE_DATA array.
    # Hash also contains other data, like a string representing the
    # bases option for CASAVA 1.8 config.txt files. This should probably
    # be moved to the config.txt file maker.
    #
    def lane_data_for flowcell_id
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
