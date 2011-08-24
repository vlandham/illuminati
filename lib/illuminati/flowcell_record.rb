require 'yaml'
require 'illuminati/flowcell_data'
require 'illuminati/sample_multiplex'
require 'illuminati/external_data_adapter'
require 'illuminati/external_data_base'
require 'illuminati/views'

module Illuminati
  #
  # Contains all info from LIMS and SampleMultiplex.csv concerning an individual sample.
  #
  class Sample
    LIMS_DATA = [:lane, :genome, :name, :protocol]
    attr_accessor *LIMS_DATA

    attr_accessor :barcode, :barcode_type

    #
    # New instance of sample
    #
    def initialize
      @barcode = ""
      @lane = @genome = @name = @protocol = ""
      @barcode_type = :none
    end

    #
    # Add lims data from LIMSAdapter to sample.
    #
    # == Parameters:
    # lims_data::
    #   hash of lims data to add to the sample.
    #
    # == Returns:
    # self so chaining is possible.
    #
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

    #
    # Test to see if the lane data between two samples are equal.
    # Used in config.txt view to combine lanes.
    #
    def lane_equal other_sample
      [:genome, :protocol].each do |lane_data|
        if self.send(lane_data) != other_sample.send(lane_data)
          return false
        end
      end
      true
    end

    #
    # Returns TruSeq index for sample. Empty string is returned if
    # Sample is not indexed.
    #
    def illumina_barcode
      self.barcode_type == :illumina ? self.barcode : ""
    end

    #
    # Returns custom barcode for sample. Empty string is returned if
    # no custom barcode used for sample.
    #
    def custom_barcode
      self.barcode_type == :custom ? self.barcode : ""
    end

    #
    # Returns string that is used for the barcode portion of files
    # representing sample. This can be either the illumina / custom barcode or "NoIndex"
    #
    def barcode_string
      self.barcode.empty? ? "NoIndex" : self.barcode
    end

    #
    # The id for the sample. The id is the lane_barcode if there is a TruSeq barcode,
    # else it will be just the lane.
    #
    def id
      id = "#{self.lane}"
      id += "_#{illumina_barcode}" unless illumina_barcode.empty?
      id
    end

    #
    # Returns array of output files for this sample. If single read, this will
    # have only one value in the array. If it is paired-end data, this will be
    # an array of two. One fastq file name for each read.
    #
    def outputs
      id_array = []
      reads.each do |read|
        id = "s_#{self.lane}_#{read}_#{self.barcode_string}.fastq.gz"
        id_array << id
      end
      id_array
    end

    #
    # Return array of read integers. If single read, this will be [1].
    # If paired-end, this will be [1,2].
    #
    def reads
      (1..read_count).to_a
    end

    #
    # Strips special characters from name and returns cleaned name.
    #
    def clean_name
      clean_name = name.strip
      clean_name.gsub!(/\s+/,'_')
      clean_name.gsub!(/[^0-9A-Za-z_-]/, '_')
      clean_name
    end

    #
    # Returns 'Y' if sample is considered to be in a control lane
    #
    def control
      self.genome =~ /.*phi[xX].*/ ? "Y" : "N"
    end

    #
    # Returns the number of reads the sample has. 1 or 2.
    #
    def read_count
      self.protocol =~ /^eland_pair/ ? 2 : 1
    end

    #
    # Provides a string to populate the SampleSheet.csv description.
    #
    def description
      "lane #{self.lane} name #{self.clean_name}"
    end

    #
    # Returns hash of relevant Sample data.
    # Hash should be read-only and not modify
    # the Sample.
    #
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

    #
    # Output sample to yaml
    #
    def to_yaml
      self.to_h.to_yaml
    end

    #
    # Returns all data it can for use in the Sample_Report.csv.
    #
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
  #
  # Represents a Flowcell lane. Each lane contains a
  # number of samples where most of the action is.
  #
  class Lane
    attr_accessor :number, :samples, :barcode_type

    #
    # New instance of lane.
    #
    # == Parameters:
    # number::
    #   1-8 its the lane number.
    #
    def initialize number
      self.number = number
      self.samples = []
    end

    #
    # Creates new Samples and adds them to lane.
    # Deals with barcoded samples here. Adding
    # more than one sample for the lane.
    #
    # == Parameters:
    # lane_data::
    #   lane data hash from LIMS
    #
    # multiplex_lane_data::
    #   hash of multiplex data for lane
    #
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

    #
    # Helper method that should be moved elsewhere.
    # given a multiplex hash, it returns the barcode and
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

    #
    # Returns the first sample as a hash.
    # The idea being, all the lane data is really maintained in the Sample class
    # for convience. So, the first sample of the lane will have all the relevant lane
    # data.
    #
    def to_h
      samples[0].to_h if samples[0]
    end

    #
    # Is one lane equal to another?
    # Uses Sample lane_equal
    #
    def equal other_lane
      if ((!samples[0]) or (!other_lane.samples[0]))
        return false
      end
      samples[0].lane_equal(other_lane.samples[0])
    end
  end
end

module Illuminati
  #
  # Main storage class for all data concerning flowcell.
  # FlowcellRecord has many lanes, which in turn has many samples.
  # FlowcellRecord also keeps path information inside it and maintains
  # multiplex data from SampleMultiplex.csv
  #
  class FlowcellRecord
    attr_accessor :id, :lanes, :paths, :multiplex, :external_data

    #
    # Finds flowcell for particular ID and populates its fields.
    # Use this externally to create new FlowcellRecords.
    #
    # == Parameters:
    # flowcell_id::
    #   Id of the flowcell we want information on.
    #
    # paths::
    #   A path data instance. Optional. The default value should
    #   be what you want for actual use. It is passed in to simplify
    #   testing.
    #
    # == Returns:
    # Populated FlowcellRecord ready for action.
    #
    def self.find flowcell_id, paths = FlowcellData.new(flowcell_id), external_data = ExternalDataLims.new
      flowcell = FlowcellRecord.new(flowcell_id)
      flowcell.id = flowcell_id
      flowcell.paths = paths


      flowcell.get_data

      flowcell
    end

    def initialize flowcell_id
      self.id = flowcell_id
      self.lanes = []
    end

    def get_data
      self.external_data = ExternalDataAdapter.find(self.paths.base_dir)
      self.multiplex = SampleMultiplex.find(self.paths.base_dir)

      lims_lane_data = self.external_data.lane_data_for self.id
      self.add_lanes lims_lane_data, self.multiplex
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
    # Use SampleSheetView to output string representing
    # flowcell in SampleSheet.csv format.
    #
    def to_sample_sheet
      view = SampleSheetView.new(self)
      view.write
    end

    #
    # Use ConfigFileView to output string representing
    # flowcell in config.txt format.
    #
    def to_config_file
      view = ConfigFileView.new(self)
      view.write
    end

    #
    # Return Flowcell to yaml.
    #
    def to_yaml
      self.to_h.to_yaml
    end

    #
    # Return hash of relevant info in flowcell.
    #
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

    #
    # yields each sample with its associated lane for the flowcell.
    # Main way to iterate through each sample in the flowcell.
    #
    def each_sample_with_lane
      self.lanes.each do |lane|
        lane.samples.each do |sample|
          yield sample, lane
        end
      end
    end
  end
end
