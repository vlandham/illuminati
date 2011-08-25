
module Illuminati
  #
  # Interface between SampleMultiplex.csv file and Illuminati.
  # Finds and reads SampleMultiplex.csv file for flowcell and
  # translates it into an array of hash values.
  #
  class SampleMultiplex
    #
    # Main interface between SampleMultiplex and rest of Illuminati.
    # Given a starting path, find will look for SampleMultiplex.csv files
    # and parse them.
    #
    # == Parameters:
    # base_dir::
    #   Directory that SampleMultiplex.csv should be in.
    #
    # == Returns:
    # Array of hash values for each sample found in SampleMultiplex.csv file.
    # Content of this hash includes:
    #   :lane - lane number.
    #   :name - sample name.
    #   :illumina_barcode - TruSeq index if provided.
    #   :custom_barcode - Custom barcode sequence, if provided.
    # Missing values are nil.
    # If no SampleMultiplex.csv is found, an empty array is returned.
    def self.find base_dir
      data = []
      file_path = find_file(base_dir) if base_dir
      if file_path
        data = get_multiplex_data(file_path)
      end
      data
    end

    #
    # Performs actual parsing of SampleMultiplex.csv file if present.
    #
    # == Parameters:
    # multiplex_file::
    #   full path to SampleMultiplex.csv file.
    #
    # == Returns:
    # Array of hashes as described in the find method.
    #
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

    #
    # Performs cleaning of a single line from SampleMultiplex.csv to
    # prepare it for use in the rest of the system.
    #
    # == Parameters:
    # multiplex_data::
    #   One raw hash corresponding to a line in SampleMultiplex.csv.
    #
    # == Returns:
    # Cleaned version of this line hash.
    #
    def self.clean multiplex_data
      multiplex_data[:name] = clean_name(multiplex_data[:name])
      multiplex_data
    end

    #
    # Removes unwanted characters and spaces from sample name.
    # Most characters are replaced by underscore '_'
    #
    def self.clean_name raw_name
      name = raw_name
      name.gsub!(/\s+/,'')
      name.gsub!(/[^0-9A-Za-z_]/, '_')
      name
    end

    #
    # Given a base directory, attempts to find SampleMultiplex.csv file
    # in this directory. Sub-directories are not searched.
    #
    # Currently prints a lot of annoying warnings telling us if it found something.
    #
    def self.find_file(base_dir)
      rtn = nil
      path_search = File.join(base_dir, "*SampleMultiplex*.csv")
      paths = Dir.glob(path_search)
      if paths.empty?
        #puts "WARNING: No MultiplexSamples.csv found for flowcell"
        #puts "         Assuming no lane is multiplexed on flowcell"
        #puts ""
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
