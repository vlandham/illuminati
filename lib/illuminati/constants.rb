module Illuminati
  #
  #TODO: all these should be in a config file
  #
  # Location of CASAVA 1.8's bin directory
  CASAVA_PATH = "/home/solexa/CASAVA_1.8.1/bin"
  # List emailer uses to email out messages.
  EMAIL_LIST = ["jfv@stowers.org"]
  # Path to put quality control files in.
  QC_PATH = "/qcdata"
  # Location of external scripts that are needed by Illuminati.
  SCRIPT_PATH = "/solexa/bin/scripts"
  # Location where startup scripts will be placed.
  ADMIN_PATH = "/solexa/runs"
  # Location of log files.
  LOGS_PATH = "/solexa/runs/log"
  # Root directory of location of flowcell run directories.
  FLOWCELL_PATH_BASE = "/solexa"


  # Relative path of the Basecalls directory
  BASECALLS_PATH = File.join("Data", "Intensities", "BaseCalls")
  # Relative path of Illuminati's fastq renaming directory.
  FASTQ_COMBINE_PATH = "all"
  # Relative path of Illuminati's fastq renaming directory.
  FASTQ_UNDETERMINED_COMBINE_PATH = "undetermined"
  # Relative path of Illuminati's export renaming directory.
  ELAND_COMBINE_PATH = "all"
  # Relative path of Illuminati's fastq filtering directory.
  FASTQ_FILTER_PATH = "filter"
  # Pattern to use when searching for the Project directory.
  PROJECT_PATTERN = "Project_*"
  # Pattern to use when searching for the unaligned stats directory.
  FASTQ_STATS_PATTERN = "Basecall_Stats_*"
  # Pattern to use when searching for the aligned stats directory.
  ELAND_STATS_PATTERN = "Summary_Stats_*"
end

module Illuminati
  class Paths
    def self.base
      FLOWCELL_PATH_BASE
    end
  end
end
