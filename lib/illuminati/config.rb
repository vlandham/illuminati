require 'yaml'
require 'logger'

module Illuminati
  class Config
    def self.parse_config
      base_config = {}
      begin
        base_config = YAML.load_file(( ENV['ILLUMINATI_CONFIG'] or 'config.yaml' ))
      rescue Errno::ENOENT
        puts 'config.yaml not found - will assume default settings'
      end

      set_defaults(base_config)
    end

    def self.set_defaults config
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
      config
    end
  end
end
