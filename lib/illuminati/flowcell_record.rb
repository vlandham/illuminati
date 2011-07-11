require 'illuminati/flowcell_data'
require 'illuminati/sample_multiplex'
require 'illuminati/lims_adapter'

module Illuminati
  class Sample
    LIMS_DATA = [:lane, :genome, :name, :samples, :cycles, :type, :protocol]
    attr_accessor *LIMS_DATA

    attr_accessor :barcode

    def initialize
      @barcode = ""
    end

    def add_lims_data lims_data
      lims_data.each do |key, value|
        equals_key = (key.to_s + "=")
        if LIMS_DATA.include?(key)
          if self.respond_to?(equals_key)
            self.send(equals_key, value)
          else
            puts "ERROR: lane does not have attribute: #{key}"
          end
        end
      end
    end

    def add_multiplex_data multiplex_data
    end

    def clean_name
      clean_name = name.gsub(/\s+/,'')
      clean_name.gsub!(/[^0-9A-Za-z_]/, '_')
      clean_name
    end

    def control
      self.genome =~ /.*phiX.*/ ? "Y" : "N"
    end

    def read_count
      self.protocol == "eland_pair" ? 2 : 1
    end
  end
end

module Illuminati
  class Lane
    attr_accessor :number, :samples, :barcode_type

    def initialize number
      self.number = number
      self.samples = []
    end

    def add_samples lane_data, multiplex_lane_data
      if multiplex_lane_data.empty?
        sample = Sample.new
        sample.add_lims_data(lane_data)
        self.samples << sample
        self.barcode_type = :none
      else
        multiplex_lane_data.each do |multi_data|
          sample = Sample.new
          sample.add_lims_data(lane_data)
          type, barcode = barcode_of(multi_data)
          sample.barcode = barcode
          self.barcode_type = type
          self.samples << sample
        end
      end
      self.samples.sort! {|x,y| x.barcode <=> y.barcode}
    end

    def barcode_of multiplex_data
      if multiplex_data[:illumina_barcode] and multiplex_data[:custom_barcode]
        puts "ERROR: multiplex data has both illumina and custom barcodes"
        raise "too many barcodes"
      elsif multiplex_data[:illumina_barcode]
        return :illumina, multiplex_data[:illumina_barcode]
      elsif multiplex_data[:custom_barcode]
        return :custom, multiplex_data[:custom_barcode]
      else
        return :none, ""
      end
    end

    def equal other_lane
    end
  end
end

module Illuminati
  class FlowcellRecord
    attr_accessor :id, :lanes, :paths

    def self.find flowcell_id
      self.id = flowcell_id
      flowcell = FlowcellRecord.new(flowcell_id)
      flowcell.paths = FlowcellData.new(flowcell_id)

      lims_lane_data = LimsAdapter.lanes(flowcell_id)
      multiplex_data = MultiplexAdapter.find(flowcell_id)
      flowcell.add_lanes lims_lane_data, multiplex_data

      flowcell
    end

    def initialize flowcell_id
      self.id = flowcell_id
    end

    def add_lanes lims_lane_data, multiplex_data
      lims_lane_data.each do |lims_lane|
        lane_number = lims_lane[:lane].to_i
        lane_multiplex_data = multiplex_data.select {|data| data[:lane].to_i == lane_number}
        lane = Lane.new(lane_number)
        lane.add_samples(lims_lane, lane_multiplex_data)
        self.lanes << lane
      end
      self.lanes.sort! {|x,y| x.number <=> y.number}
    end
  end
end
