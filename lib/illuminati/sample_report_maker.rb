require 'illuminati/flowcell_record'
require 'illuminati/tab_file_parser'
require 'illuminati/html_parser'

module Illuminati
  class SampleReportMaker
    DATA_NAMES = [:output, :lane, :name, :illumina, :custom, :read, :genome]
    def self.make flowcell_id
      @flowcell = FlowcellRecord.find(flowcell_id)
      demultiplex_filename = File.join(@flowcell.paths.unaligned_stats_dir, "Demultiplex_Stats.htm")
      html_parser = HtmlParser.new
      @demultiplex_data = html_parser.table_data(demultiplex_filename)[0]
      @tab_parser = TabFileParser.new

      sample_report = ["output", "lane", "sample name", "illumina index",
                       "custom barcode", "read", "reference"].join(",")
      sample_report += ","
      sample_report += ["# reads"].join(",")
      sample_report += "\n"

      @flowcell.each_sample_with_lane do |sample, lane|
        read_data = data_for sample
        read_data.each do |sample_read_data|
          sample_read_string = sample_read_data.join(",")
          sample_report += sample_read_string
          sample_report += "\n"
        end
      end
      sample_report
    end

    def self.data_for sample
      all_read_data = []
      sample_datas = sample.sample_report_data

      sample_datas.each do |sample_data|
        data = DATA_NAMES.collect {|key| sample_data[key]}
        count = count_from_custom_barcode sample
        if !count
          count = count_from_demultiplex_sample_data sample
        end

        data << count
        all_read_data << data
      end
      all_read_data
    end

    def self.count_from_demultiplex_sample_data sample
      count = nil
      demultiplex_sample_data = demultiplex_data_for_sample sample, @demultiplex_data
      if !demultiplex_sample_data
        puts "ERROR: sample report maker cannot find demultiplex data for #{sample.id}"
      else
        count = demultiplex_sample_data["# Reads"]
        count.gsub!(",","")
      end
      count
    end

    def self.count_from_custom_barcode sample
      barcode_filename = @flowcell.paths.custom_barcode_path_out(sample.lane.to_i)
      if File.exists? barcode_filename
        count = nil
        all_barcode_data = @tab_parser.parse(barcode_filename)
        barcode_data = barcode_data_for_sample sample, all_barcode_data
        if !barcode_data
          puts "ERROR: sample report maker cannot find barcode data for #{sample.id} #{sample.barcode}"
        else
          count = barcode_data["Count"]
        end
      end
      count
    end

    def self.barcode_data_for_sample sample, barcoded_data
      barcoded_data.each do |barcode_line|
        if barcode_line["Barcode"] == sample.custom_barcode
          return barcode_line
        end
      end
      nil
    end

    def self.demultiplex_data_for_sample sample, demultiplex_data
      demultiplex_data.each do |demultiplex_sample|
        if demultiplex_sample["Sample ID"] == sample.id
          return demultiplex_sample
        end
      end
      nil
    end
  end
end

