
module Illuminati
  class SampleMultiplex
    def self.find base_dir
      data = []
      file_path = find_file(base_dir)
      if file_path
        data = get_multiplex_data(file_path)
      end
      data
    end

    def self.get_multiplex_data(multiplex_file)
      header = [:lane, :name, :illumina_barcode, :custom_barcode]
      data = []
      if multiplex_file and File.exists?(multiplex_file)
        lines = []
        File.open(multiplex_file, 'r') do |file|
          lines = file.readlines
        end
        # get rid of header
        lines.shift
        lines.each do |line|
          line_data = line.chomp.split(",").collect {|d| d.strip}
          line_hash = {}
          header.each_with_index do |h,index|
            line_hash[h] = line_data[index] if (line_data[index] and !line_data[index].empty?)
          end
          line_hash = clean line_hash
          data << line_hash
        end
      end
      data
    end

    def self.clean multiplex_data
      multiplex_data[:name] = clean_name(multiplex_data[:name])
      multiplex_data
    end

    def self.clean_name raw_name
      name = raw_name
      name.gsub!(/\s+/,'')
      name.gsub!(/[^0-9A-Za-z_]/, '_')
      name
    end

    def self.find_file(base_dir)
      rtn = nil
      path_search = File.join(base_dir, "*SampleMultiplex*.csv")
      paths = Dir.glob(path_search)
      if paths.empty?
        puts "WARNING: No MultiplexSamples.csv found for flowcell"
        puts "         Assuming no lane is multiplexed on flowcell"
        puts ""
      elsif paths.size > 1
        puts "ERROR: Mulitple SampleMultiplex.csv files found"
        puts "       path searched: #{path_search} found: #{paths.size} matches"
        raise "too many multiplex matches"
      else
        puts "INFO: Found multiplex file at #{paths[0]}"
        rtn = paths[0]
      end
      rtn
    end
  end
end
