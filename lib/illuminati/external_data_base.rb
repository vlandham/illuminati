module Illuminati
  #
  # Illuminati needs information about the data
  # on the lanes of the flowcell that it cannot acquire
  # from the contents of a run directory.
  #
  # Specifically, it needs two things:
  # * sample names, genomes, etc to use for each lane
  # * where to ultimately distribute the data for each lane
  #
  # This base class provides an interface for sub-classes to
  # follow in order to provide this information.
  #
  # Traditionally, we use our LIMS system which stores this data.
  # However, for other labs, or for times when a flowcell is not in
  # LIMS, it should be possible to add a subclass of ExternalDataBase
  # that provides the required information based on other sources - like a
  # flat file, or an alternate lims database.
  #
  # NOTE: This data really should be at a per-sample level, and not at a per-lane
  # level. This deficiency arises from our legacy LIMS system which cannot handle
  # barcodes / indexes - and thus each lane is considered a single sample. Currently,
  # The use of the SampleMultiplex.csv file is our solution to get around this problem.
  # In the future, all data will be combined in the LIMS and this interface will
  # change to deal with data at the sample level.
  #
  class ExternalDataBase

    def initialize
    end

    #
    # This method returns an array of hashes describing each lane in the flowcell
    # with the ID of flowcell_id.
    # Each hash contains the following keys:
    # { :flowcell => The flowcell ID. Should be same as input flowcell_id,
    #   :lane => String name of lane (1 - 8),
    #   :genome => Code for genome used for lane. Should correlate to folder name in genomes dir,
    #   :name => Sample name of the sample in the lane. Replaced by data from SampleMultiplex.csv if multiplexed,
    #   :cycles => String providing the number of cycles the flowcell lane was run,
    #   :protocol => Should be either "eland_extended" or "eland_pair", 
    #   :bases => Should be the string used in the config.txt file to indicate which bases to use, i.e. "Y*" or "Y* Y*"
    # }
    #
    def lane_data_for flowcell_id
      raise "implement lane_data_for in sub-class"
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
      raise "implement distributions_for in sub-class"
    end
  end
end
