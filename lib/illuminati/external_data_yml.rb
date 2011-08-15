class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end


module Illuminati
  class ExternalDataYml
    def initialize filename
      super
      if File.exists? filename
        @data = Hash[YAML::load(open(filename))]
        @data = Hash.transform_keys_to_symbols(@data)
      else
        raise "ExternalDataYml: no file found #{filename}"
      end
    end

    def lane_data_for flowcell_id
      @data[:lanes] ? @data[:lanes] : []
    end

    def distributions_for flowcell_id
      @data[:distributions] ? @data[:distributions] : []
    end
  end
end
