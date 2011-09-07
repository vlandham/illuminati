require 'yaml'
require 'logger'

module Illuminati

  class Config
    def self.parse_config
      return YAML.load_file(( ENV['ILLUMINATI_CONFIG'] or 'config.yaml' ))
    rescue Errno::ENOENT
      Logger.new(STDOUT).warn('config.yaml not found - will assume default settings')
      return {}
    end
  end

  config = Config.parse_config
  config['casava_path']         ||= '/home/solexa/CASAVA_1.8.1/bin'
  config['email_list']          ||= ['jfv@stowers.org']
  config['qc_path']             ||= '/qcdata'
  config['script_path']         ||= '/solexa/bin/scripts'
  config['admin_path']          ||= '/solexa/runs'
  config['logs_path']           ||= '/solexa/runs/log'
  config['flowcell_path_base']  ||= '/solexa'
  config['basecalls_path']      ||= File.join('Data', 'Intensities', 'BaseCalls')
  config['fastq_combine_path']  ||= 'all'
  config['fastq_undetermined_combine_path'] ||= 'undetermined'
  config['eland_combine_path']  ||= 'all'
  config['fastq_filter_path']   ||= 'filter'
  config['project_pattern']     ||= 'Project_*'
  config['fastq_stats_pattern'] ||= 'Basecall_Stats_*'
  config['eland_stats_pattern'] ||= 'Summary_Stats_*'
  config['email_server']        ||= 'localhost:25'
  config['web_dir_root']        ||= 'http://molbio/solexaRuns/'
  config['num_leading_dirs_to_strip'] ||= '1'


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
