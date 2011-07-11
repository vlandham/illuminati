require 'illuminati/flowcell_data'
require 'illuminati/sample_multiplex'
require 'illuminati/lims_adapter'

module Illuminati
  class Sample
    LIMS_DATA = [:lane, :genome, :name, :samples, :cycles, :type, :protocol]
    attr_accessor *LIMS_DATA

    def initialize
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
    attr_accessor :number, :samples

    def initialize number
      self.number = number
      self.samples = []
    end

    def add_sample sample
      samples << sample
    end

    def equal other_lane
    end
  end
end

module Illuminati
class FlowcellRecord
  attr_accessor :id, :samples, :paths

  def self.find flowcell_id
    flowcell = FlowcellRecord.new(flowcell_id)
    flowcell.paths = FlowcellData.new(flowcell_id)

    lims_lane_data = LimsAdapter.lanes(flowcell_id)
    multiplex_data = MultiplexAdapter.find(flowcell_id)

    flowcell
  end

  def initialize flowcell_id
    self.id = flowcell_id
  end

end

end
