require 'yaml'
require 'illuminati/flowcell_data'
require 'illuminati/sample_multiplex'
require 'illuminati/lims_adapter'
require 'illuminati/views'

module Illuminati
  class Sample
    LIMS_DATA = [:lane, :genome, :name, :samples, :cycles, :type, :protocol, :bases]
    attr_accessor *LIMS_DATA

    attr_accessor :barcode, :barcode_type

    def initialize
      @barcode = ""
      @barcode_type = :none
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
      self
    end

    def lane_equal other_sample
      [:genome, :cycles, :protocol].each do |lane_data|
        if self.send(lane_data) != other_sample.send(lane_data)
          return false
        end
      end
      true
    end

    def illumina_barcode
      self.barcode_type == :illumina ? self.barcode : ""
    end

    def custom_barcode
      self.barcode_type == :custom ? self.barcode : ""
    end

    def barcode_string
      self.barcode.empty? ? "NoIndex" : self.barcode
    end

    def id
      id = "#{self.lane}"
      id += "_#{illumina_barcode}" unless illumina_barcode.empty?
      id
    end

    def outputs
      id_array = []
      reads.each do |read|
        id = "s_#{self.lane}_#{read}_#{self.barcode_string}.fastq.gz"
        id_array << id
      end
      id_array
    end

    def reads
      (1..read_count).to_a
    end

    def clean_name
      clean_name = name.strip
      clean_name.gsub!(/\s+/,'_')
      clean_name.gsub!(/[^0-9A-Za-z_-]/, '_')
      clean_name
    end

    def control
      self.genome =~ /.*phi[xX].*/ ? "Y" : "N"
    end

    def read_count
      self.protocol =~ /^eland_pair/ ? 2 : 1
    end

    def description
      "lane #{self.lane} name #{self.clean_name}"
    end

    def to_h
      data_fields = LIMS_DATA
      data_fields << :id
      data_fields << :barcode << :barcode_type
      data_fields << :read_count
      data = Hash.new
      data_fields.each do |field|
        if self.respond_to?(field)
          value = self.send(field)
          data[field] = value unless !value
        else
          puts "ERROR: yaml field not present: #{field}"
        end
      end
      # ensure these aren't editable afterwards
      cloned_data = Marshal.load(Marshal.dump(data))
      cloned_data
    end

    def to_yaml
      self.to_h.to_yaml
    end

    def sample_report_data
      all_reads_data = []
      outputs.each_with_index do |output, index|
        data = {:output => output, :lane => lane, :name => name,
                :illumina => illumina_barcode, :custom => custom_barcode,
                :read => reads[index], :genome => genome}
        all_reads_data << data
      end
      all_reads_data
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
          sample.barcode_type = type
          sample.name = multi_data[:name] if multi_data[:name]
          self.barcode_type = type
          self.samples << sample
        end
      end
      self.samples.sort! {|x,y| x.barcode <=> y.barcode}
    end

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

    def to_h
      samples[0].to_h if samples[0]
    end

    def equal other_lane
      if ((!samples[0]) or (!other_lane.samples[0]))
        return false
      end
      samples[0].lane_equal(other_lane.samples[0])
    end
  end
end

module Illuminati
  class FlowcellRecord
    attr_accessor :id, :lanes, :paths, :multiplex

    def self.find flowcell_id, paths = FlowcellData.new(flowcell_id)
      flowcell = FlowcellRecord.new(flowcell_id)
      flowcell.paths = paths
      flowcell.id = flowcell_id

      lims_lane_data = LimsAdapter.lanes(flowcell_id)
      flowcell.multiplex = SampleMultiplex.find(paths.base_dir)
      flowcell.add_lanes lims_lane_data, flowcell.multiplex

      flowcell
    end

    def initialize flowcell_id
      self.id = flowcell_id
      self.lanes = []
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

    def to_sample_sheet
      view = SampleSheetView.new(self)
      view.write
    end

    def to_config_file
      view = ConfigFileView.new(self)
      view.write
    end

    def to_yaml
      self.to_h.to_yaml
    end

    def to_h
      hash = Hash.new
      hash[:flowcell_id] = self.id
      hash[:samples] = []
      each_sample_with_lane do |sample, lane|
        hash[:samples] << sample.to_h
      end
      hash[:paths] = self.paths.to_h
      hash
    end

    def each_sample_with_lane
      self.lanes.each do |lane|
        lane.samples.each do |sample|
          yield sample, lane
        end
      end
    end
  end
end
