require 'erb'

module Illuminati
  class ConfigFileView
    CONFIG_TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "assests", "config.txt.erb"))
    attr_accessor :lanes, :input_dir, :flowcell_id
    def initialize flowcell_record
      @lanes = squash_lanes(flowcell_record)
      @input_dir = flowcell_record.paths.unaligned_dir
    end

    def write
      template = ERB.new File.new(CONFIG_TEMPLATE_PATH).read, nil, "%<>"
      output = template.result(binding)
    end

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
  class SampleSheetView
    def initialize flowcell_record
      @flowcell = flowcell_record

    end

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


