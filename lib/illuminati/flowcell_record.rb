require 'illuminati/flowcell_data'

module Illuminati
  class Sample
    LIMS_DATA = [:lane, :genome, :name, :samples, :cycles, :type, :protocol]
    attr_accessor *LIMS_DATA

    def initialize
    end

    def add_lims_data lims_data
      lims_data.each do |key, value|
        equals_key = (key.to_string + "=")
        if LIMS_DATA.include?(key)
          if self.respond_to?(equals_key)
            self.send(equals_key, value)
          else
            puts "ERROR: lane does not have attribute: #{key}"
          end
        end
      end
    end

    def add_multiplex_data multiplex_data
    end

    def clean_name
      clean_name = name.gsub(/\s+/,'')
      clean_name.gsub!(/[^0-9A-Za-z_]/, '_')
      clean_name
    end

    def control
      self.genome =~ /.*phiX.*/ ? "Y" : "N"
    end

    def read_count
      self.protocol == "eland_pair" ? 2 : 1
    end
  end
end

module Illuminati

class LimsAdapter
  LANE_DATA = [:flowcell, :lane, :genome, :name, :samples, :lab, :unknown, :cycles, :type, :protocol]

  CONVERSIONS = {
    "Drosophila_melanogaster.BDGP5.4.54" => [/.*BDGP5.*/],
    "ce6" => [/ce6/],
    "dp3" => [/dp3/],
    "droSim1" => [/.*simulans.*/],
    "droAna2" => [/.*ananassae.*/],
    "mm9" => [/.*mm9.*/, /.*musculus.*/],
    "sacCer2" => [/.*sac[C|c]er2.*/, /.*[C|c]erevisiae.*/], 
    "hg19" => [/.*[H|h]uman.*/,/.*hg19.*/,/.*[S|s]apien.*/],
    "phiX" => [/.*phiX.*/, /.*phix.*/],
    "dm3" => [/.*dm3.*/, /.*[D|d]rosophila.*/],
    "pombe_9-2010" => [/.*[P|p]ombe.*/]
  }

  def self.query command, flowcell_id
    query_results = %x[perl #{SCRIPT_PATH}/ngsquery.pl #{command} #{flowcell_id}]
    query_results.force_encoding("iso-8859-1")
    rows = query_results.split("\n")
    split_rows = rows.collect {|row| row.split("\t")}
    split_rows
  end

  def self.lanes flowcell_id
    raw_lanes = query("fc_lane_library_samples", flowcell_id)
    lanes = Array.new
    raw_lanes.each do |raw_lane|
      lane_data = Hash.new
      LANE_DATA.each_with_index do |header, index|
        lane[header] = raw_lane[index]
      end
      lanes << lane_data
    end
    lanes
  end

  def self.clean_lane lane_data
    lane_data[:organism] = translate_organism(lane_data[:organism])
    lane_data[:protocol] = translate_protocol(lane_data[:protocol])
    lane_data[:bases] = get_bases(lane_data[:protocol])
    lane_data
  end

  def self.translate_protocol raw_protocol
    raw_protocol.downcase =~ /.*pair.*/ ? "eland_pair" : "eland_extended"
  end

  def self.get_bases protocol
    protocol == "eland_pair" ? "Y*,Y*" : "Y*"
  end

  def self.translate_organism raw_organism
    new_type = raw_organism
    matched = false
    CONVERSIONS.each do |valid_name, matches|
      matches.each do |match|
        if new_type =~ match
          new_type = valid_name
          matched = true
          break
        end
      end
      break if matched
    end
    puts "ERROR: #{new_type} not in conversions table" unless matched
    new_type
  end

end

class MultiplexAdapter
  def self.find base_dir
    data = []
    file_path = find_multiplex_file(base_dir)
    if file_path
      data = get_multiplex_data(file_path)
    end
    data
  end

  def self.get_multiplex_data(multiplex_file)
    header = [:lane, :name, :illumina_barcode, :custom_barcode]
    data = []
    if file_path and File.exists?(multiplex_file)
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
          line_hash[h] = line_data[index]
        end
        clean_name line_hash
        data << line_hash
      end
    end
    data
  end

  def self.clean multiplex_data
    multiplex_data[:name] = clean_name(multiplex_data[:name])
    multiplex_data[:control] = get_control(multiplex_data[:organism])
  end

  def self.clean_name raw_name
    name = raw_name
    name.gsub!(/\s+/,'')
    name.gsub!(/[^0-9A-Za-z_]/, '_')
    name
  end


  def self.find_multiplex_file(base_dir)
    rtn = nil
    path_search = File.join(base_dir, "*SampleMultiplex*.csv")
    paths = Dir.glob(path_search)
    if multiplex_data.empty?
      puts "WARNING: No MultiplexSamples.csv found for #{flowcell_id}"
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

class FlowcellRecord
  attr_accessor :id, :samples, :paths

  def self.find flowcell_id
    flowcell = FlowcellRecord.new(flowcell_id)
    flowcell.paths = FlowcellData.new(flowcell_id)

    lims_lane_data = LimsAdapter.lanes(flowcell_id)
    multiplex_data = MultiplexAdapter.find(flowcell_id)

    flowcell
  end

  def initialize flowcell_id
    self.id = flowcell_id
  end

end

end
