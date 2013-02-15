#! /usr/bin/env ruby

#
# Hastily written script to create the configuration files needed for the
# rest of the primary analysis pipeline.
#
# Currently makes:
# * SampleSheet.csv - used for demultiplexing and alignment by CASAVA 1.8
# * config.txt - used for alignment by CASAVA 1.8
# * custom_barcode.txt files - used by fastx splitter in post run.
#

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'optparse'
require 'illuminati'

module Illuminati
  if __FILE__ == $0
    options = {}
    options[:lanes] = [1,2,3,4,5,6,7,8]
    options[:sample_sheet] = nil
    options[:config] = nil
    opts = OptionParser.new do |o|
      o.banner = "Usage: startup_run.rb [Flowcell Id] [options]"
      o.on("--lanes 1,2,3,4,5,6,7,8", Array, 'Specify which lanes should be run') {|b| options[:lanes] = b.collect {|l| l.to_i} }
    o.on('-s', '--sample_sheet SAMPLESHEET_NAME', String, 'Specify sample sheet name') {|b| options[:sample_sheet] = b}
    o.on('-c', '--config CONFIG_NAME', String, 'Specify config.txt name') {|b| options[:config] = b}
      o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
      o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
    end

    opts.parse!

    flowcell_id = ARGV[0]

    config_output_file = options[:config]
    sample_sheet_output_file = options[:sample_sheet]

    if flowcell_id
      puts "Flowcell ID: #{flowcell_id}"
    else
      puts "ERROR: no flow cell ID provided"
      exit
    end

    flowcell = FlowcellRecord.find(flowcell_id)

    lanes_with_barcodes = CustomBarcodeFileMaker.make flowcell

    if !lanes_with_barcodes.empty?
      puts "Custom Barcode files made for lanes #{lanes_with_barcodes.join(", ")}"
    else
      puts "No custom Barcodes found"
    end

    sample_sheet_data = flowcell.to_sample_sheet options[:lanes]
    if sample_sheet_output_file
      File.open(sample_sheet_output_file, 'w') do |file|
        file << sample_sheet_data
      end
    else
      puts "SampleSheet.csv"
      puts sample_sheet_data
      puts ""
    end

    config_file_data = flowcell.to_config_file options[:lanes]
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


