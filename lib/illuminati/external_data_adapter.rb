require 'illuminati/external_data_lims'
require 'illuminati/external_data_yml'
require 'illuminati/external_data_lims_new'
require 'illuminati/external_data_lims_test'

module Illuminati
  class ExternalDataAdapter

    def self.find(base_dir)
      yml_file = find_yml_file(base_dir)
      if yml_file
        puts "WARNING: Using yml external data at #{yml_file}"
        return ExternalDataYml.new(yml_file)
      else
        return ExternalDataLimsNew.new(base_dir)
      end
    end

    def self.find_yml_file(base_dir)
      rtn = nil
      path_search = File.join(base_dir, "*external_data*.yml")
      paths = Dir.glob(path_search)
      if paths.size > 1
        puts "ERROR: Mulitple SampleMultiplex.csv files found"
        puts "       path searched: #{path_search} found: #{paths.size} matches"
        raise "too many multiplex matches"
      elsif paths.size == 1
        rtn = paths[0]
      end
      rtn
    end
  end
end
