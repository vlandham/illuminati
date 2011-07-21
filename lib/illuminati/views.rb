require 'erb'

module Illuminati
  #
  # Responsible for organizing flowcell record into output used to generate a config.txt file for
  # CASAVA 1.8 ELANDv2e alignment.
  #
  # Uses config.txt.erb in assests directory for most of the formating of the config.txt file.
  #
  class ConfigFileView
    # Location of the erb template file to use to build config.txt
    CONFIG_TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "assests", "config.txt.erb"))
    attr_accessor :lanes, :input_dir, :flowcell_id

    #
    # Create new instance of view.
    #
    # == Parameters
    # flowcell_record::
    #   Instance of FlowcellRecord to create a config.txt file from.
    def initialize flowcell_record
      @lanes = squash_lanes(flowcell_record)
      @input_dir = flowcell_record.paths.unaligned_dir
    end

    #
    # Outputs flowcell record into config.txt format.
    #
    # == Returns:
    # Doesn't actually write to file, but instead returns string representation of config.txt.
    # This was done mostly as a convience during testing.
    #
    def write
      template = ERB.new File.new(CONFIG_TEMPLATE_PATH).read, nil, "%<>"
      output = template.result(binding)
    end

    #
    # Groups similar lanes of flowcell record to make config.txt output shorter.
    # We try to determine which lanes have the same parameters and then group them
    # for outputting to config.txt. This step isn't required, but results in config.txt files
    # that are much shorter and more concise.
    #
    # == Parameters:
    # flowcell_record::
    #   FlowcellRecord to look at.
    #
    # == Returns:
    # Array of lane data arrays. Each lane data array will have the values needed to
    # generate config.txt contents for one or more lanes. See the config.txt.erb file
    # for details on how these are used.
    #
    def squash_lanes flowcell_record
      squashed_lane_data = []
      current_lane_index = 0
      squashed_lane_data << flowcell_record.lanes[current_lane_index].to_h
      flowcell_record.lanes[1..-1].each do |lane|
        current_lane = squashed_lane_data[current_lane_index]
        if flowcell_record.lanes[current_lane_index].equal(lane)
          current_lane[:lane] = current_lane[:lane].to_s << lane.number.to_s
          squashed_lane_data[current_lane_index] = current_lane
        else
          squashed_lane_data << lane.to_h
          current_lane_index += 1
        end
      end
      squashed_lane_data
    end
  end
end

module Illuminati
  #
  # SampleSheet.csv is required by CASAVA 1.8 to perform demultiplexing and alignment.
  # This view is responsible for generating this csv file content from a FlowcellRecord.
  #
  class SampleSheetView
    #
    # Create new instance of this view.
    #
    # == Parameters:
    # flowcell_record::
    #   the FlowcellRecord to generate a SampleSheet.csv from.
    def initialize flowcell_record
      @flowcell = flowcell_record

    end

    #
    # Returns FlowcellRecord data in SampleSheet.csv form. Does not
    # actually write the contents to file.
    #
    # == Returns:
    # String which can be saved as SampleSheet.csv and contains all the
    # data required for all lanes / samples. This data is acquired from
    # the FlowcellRecord which in turn acquires it from the LIMS system and
    # the SampleMultiplex.csv file (if present).
    #
    def write
      sample_sheet =  ["fcid", "lane", "sampleid",
                       "sampleref", "index", "description",
                       "control", "recipe", "operator",
                       "sampleproject"].join(",")
      sample_sheet += "\n"

      #lanes_added used to exclude lanes with custom barcode
      #but no illumina barcode
      lanes_added = []
      @flowcell.each_sample_with_lane do |sample, lane|
        data = []
        if !lanes_added.include?(sample.lane) or (sample.illumina_barcode and !sample.illumina_barcode.empty?)
          data << @flowcell.id << sample.lane << sample.id
          data << sample.genome << sample.illumina_barcode
          data << sample.description << sample.control
          data << "see lims" << "see lims"
          data << @flowcell.id
          lanes_added << sample.lane
          sample_sheet += data.join(",")
          sample_sheet += "\n"
        end
      end
      sample_sheet
    end
  end
end
