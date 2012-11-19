require 'yaml'
require 'illuminati/flowcell_paths'
require 'illuminati/external_data_adapter'
require 'illuminati/external_data_base'
require 'illuminati/views'

module Illuminati
  #
  # Contains all info from external data concerning an individual sample.
  #
  class Sample
    # This is all the sample data expected from the external data source.
    # See documentation in ExternalDataBase for more information
    EXTERNAL_DATA = [:lane, :genome, :name, :protocol, :barcode, :barcode_type, :raw_barcode, :raw_barcode_type, :order, :lib_id]
    attr_accessor *EXTERNAL_DATA

    attr_accessor :parent_lane

    #
    # New instance of sample
    #
    def initialize
      @barcode = ""
      @lane = @genome = @name = @protocol = ""
      @parent_lane = nil
      @barcode_type = :none
    end

    #
    # Add external data from external data source (LIMS or flatfile) to sample.
    #
    # == Parameters:
    # external_data::
    #   hash of lims/file data to add to the sample.
    #
    # == Returns:
    # self so chaining is possible.
    #
    def add_external_data external_data
      external_data.each do |key, value|
        equals_key = (key.to_s + "=")
        if EXTERNAL_DATA.include?(key)
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

    def illumina_barcode_string
      barcode = illumina_barcode
      # cases when illumina and custom barcodes are on the same lane
      # if this isn't an illumina barcoded sample, but the lane includes
      # an illumina barcoded sample, then set the barcode for this
      # to be 'Undetermined'
      # else set it to be 'NoIndex'
      if barcode == "" and self.parent_lane and self.parent_lane.samples.size > 1 and
        self.parent_lane.include_illumina_barcoded_sample?
        barcode = "Undetermined"
      end

      barcode = barcode == "" ? "NoIndex" : barcode
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
      b_string = self.custom_barcode
      if b_string.empty?
        b_string = self.illumina_barcode_string
      end
      b_string
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
      data_fields = EXTERNAL_DATA
      data_fields << :id
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
                :read => reads[index], :genome => genome, :order => order, :lib_id => lib_id}
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
    attr_accessor :number, :samples

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
    # Add samples for lane
    #
    # == Parameters:
    # external_sample_data::
    #   Sample data from external source for this lane.
    #   NOTE: should be only sample data for the current
    #   Lane instance. NOT all sample data values.
    #
    def add_samples external_sample_data
      external_sample_data.each do |sample_data|
        sample = Sample.new
        sample.add_external_data(sample_data)
        sample.parent_lane = self
        self.samples << sample
      end
      samples.sort! do |x,y|
        comp = x.lane <=> y.lane
        comp.zero? ? (x.barcode_string <=> y.barcode_string) : comp
      end
      #samples.sort! {|x,y| x.id <=> y.id}
      samples
    end

    #
    # Returns true if at least one sample on this lane uses illumina barcodes
    #
    def include_illumina_barcoded_sample?
      include_illumina = false
      # should set include_illumina to true if at least one illumina indexed sample on lane
      self.samples.each {|samp| include_illumina ||= (samp.barcode_type == :illumina)}
      include_illumina
    end

    #
    # Method to provide the barcode type of the lane
    # Acquires data from the first sample, if samples
    # are present
    #
    def barcode_type
      rtn = :none
      rtn = samples[0].barcode_type if samples[0]
      rtn
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
    attr_accessor :id, :lanes, :paths, :external_data

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
    # external_data::
    #   Optional. If provided, this will be used as the source of the external
    #   data required for the flowcell record to function.
    #   If not present, the FlowcellRecord will use ExternalDataAdapter to
    #   get its external data either from a flatfile or from the configured lims system.
    #
    # == Returns:
    # Populated FlowcellRecord ready for action.
    #
    def self.find flowcell_id, paths = FlowcellPaths.new(flowcell_id), external_data = nil
      flowcell = FlowcellRecord.new(flowcell_id)
      flowcell.id = flowcell_id
      flowcell.paths = paths
      if external_data
        flowcell.external_data = external_data
      else
        flowcell.external_data = ExternalDataAdapter.find(flowcell.paths.base_dir)
      end

      flowcell.add_samples

      flowcell
    end

    #
    # Initialize flowcell record.
    #
    # NOTE: the FlowcellRecord::find method is the preferred way
    # to get an instance of a flowcell
    #
    # == Parameters:
    # flowcell_id:
    #   ID of the flowcell this record represents
    def initialize flowcell_id
      self.id = flowcell_id
      self.lanes = []
    end

    #
    # Gets sample data from external data source and
    # populates flowcell record with lane and sample information
    #
    # The result of this function is that the FlowcellRecord instance
    # should have all sample and lane data required for further processing
    # by illuminati
    #
    # Method assumes external_data is present and points to the appropriate
    # external data source. This method is called automatically when using the
    # FlowcellRecord::find class method.
    #
    def add_samples
      external_sample_data = self.external_data.sample_data_for self.id
      lanes_in_sample_data = external_sample_data.collect {|s| s[:lane].to_i}.uniq
      lanes_in_sample_data.each do |lane_num|
        lane = Lane.new(lane_num)
        lane_samples = external_sample_data.select {|s| s[:lane].to_i == lane_num}
        lane.add_samples(lane_samples)
        self.lanes << lane
      end
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
