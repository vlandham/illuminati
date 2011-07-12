#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

module Illuminati
  if __FILE__ == $0

    flowcell_id = ARGV[0]

    config_output_file = ARGV[1]
    sample_sheet_output_file = ARGV[2]

    if flowcell_id
      puts "Flowcell ID: #{flowcell_id}"
    else
      puts "ERROR: no flow cell ID provided"
      exit
    end

    flowcell = FlowcellRecord.find(flowcell_id)

    lanes_with_barcodes = CustomBarcodeFileMaker.make flowcell.multiplex, flowcell.paths

    if !lanes_with_barcodes.empty?
      puts "Custom Barcode files made for lanes #{lanes_with_barcodes.join(", ")}"
    else
      puts "No custom Barcodes found"
    end

    sample_sheet_data = flowcell.to_sample_sheet
    if sample_sheet_output_file
      File.open(sample_sheet_output_file, 'w') do |file|
        file << sample_sheet_data
      end
    else
      puts "SampleSheet.csv"
      puts sample_sheet_data
      puts ""
    end

    config_file_data = flowcell.to_config_file
    if config_output_file
      File.open(config_output_file, 'w') do |file|
        file << config_file_data
      end
    else
      puts "config.txt"
      puts config_file_data
      puts ""
    end

    File.open(flowcell.paths.info_path, 'w') do |file|
      file << flowcell.to_yaml
    end

  end
end


