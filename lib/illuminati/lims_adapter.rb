
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
          lane_data[header] = raw_lane[index]
        end
        lanes << clean_lane(lane_data)
      end
      lanes
    end

    def self.clean_lane lane_data
      lane_data[:genome] = translate_organism(lane_data[:genome])
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
end
