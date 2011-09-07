require 'illuminati/config'

module Illuminati
  config = Config.parse_config

  # Location of CASAVA 1.8's bin directory
  CASAVA_PATH         = File.expand_path config['casava_path']
  # List emailer uses to email out messages.
  EMAIL_LIST          = config['email_list']
  # Path to put quality control files in.
  QC_PATH             = File.expand_path config['qc_path']
  # Location of external scripts that are needed by Illuminati.
  SCRIPT_PATH         = File.expand_path config['script_path']


  # Location where startup scripts will be placed.
  ADMIN_PATH          = File.expand_path config['admin_path']
  # Location of log files.
  LOGS_PATH           = File.expand_path config['logs_path']
  # Root directory of location of flowcell run directories.
  FLOWCELL_PATH_BASE  = File.expand_path config['flowcell_path_base']


  # Relative path of the Basecalls directory
  BASECALLS_PATH      = config['basecalls_path']
  # Relative path of Illuminati's fastq renaming directory.
  FASTQ_COMBINE_PATH  = config['fastq_combine_path']
  # Relative path of Illuminati's fastq renaming directory.
  FASTQ_UNDETERMINED_COMBINE_PATH = config['fastq_undetermined_combine_path']
  # Relative path of Illuminati's export renaming directory.
  ELAND_COMBINE_PATH  = config['eland_combine_path']
  # Relative path of Illuminati's fastq filtering directory.
  FASTQ_FILTER_PATH   = config['fastq_filter_path']
  # Pattern to use when searching for the Project directory.
  PROJECT_PATTERN     = config['project_pattern']
  # Pattern to use when searching for the unaligned stats directory.
  FASTQ_STATS_PATTERN = config['fastq_stats_pattern']
  # Pattern to use when searching for the aligned stats directory.
  ELAND_STATS_PATTERN = config['eland_stats_pattern']


  EMAIL_SERVER = config['email_server']
  WEB_DIR_ROOT = config['web_dir_root']
  NUM_LEADING_DIRS_TO_STRIP  = config['num_leading_dirs_to_strip']
end

module Illuminati
  class ScriptPaths
    def self.external_scripts_path
      SCRIPT_PATH
    end

    def self.internal_scripts_path
      File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "scripts"))
    end

    def self.fastqc_script
      File.join(internal_scripts_path, "fastqc.pl")
    end

    def self.lims_script
      File.join(external_scripts_path, "ngsquery.pl")
    end

    def self.new_lims_script
      File.join(external_scripts_path, "remote", "lims_data.pl")
    end
  end
end

module Illuminati
  class Paths
    def self.base
      FLOWCELL_PATH_BASE
    end
  end
end
