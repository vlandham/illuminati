require 'illuminati/config'

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
