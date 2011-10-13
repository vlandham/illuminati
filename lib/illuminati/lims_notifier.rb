require 'json'

require 'illuminati/flowcell_record'
require 'illuminati/tab_file_parser'
require 'illuminati/casava_output_parser'

module Illuminati
  #
  # Similar to SampleReportMaker - parses output files
  # and uploads to LIMS system
  #
  class LimsUploadView
    CASAVA_TO_LIMS = {
        "Sample Yield (Mbases)" => "sampleYield",
        "Clusters (raw)" => "clustersRaw",
        "Clusters (PF)" => "clustersPF",
        "1st Cycle Int (PF)" => "firstCycleInt",
        "% intensity after 20 cycles (PF)" => "pctInt20Cyc",
        "% PF Clusters" => "pctClustersPF",
        "% Align (PF)" => "pctAlignPF",
        "Alignment Score (PF)" => "alignScore",
        "% Mismatch Rate (PF)" => "pctMismatchRate",
        "% &gt;=Q30 bases (PF)" => "pctQualityGT30",
        "Mean Quality SCore (PF)" => "meanQuality"
    }

    CUSTOM_TO_LIMS = {}

    def initialize flowcell
      @flowcell = flowcell
      @demultiplex_filename = File.join(@flowcell.paths.unaligned_stats_dir, "Demultiplex_Stats.htm")
      @sample_summary_filename = File.join(@flowcell.paths.aligned_stats_dir, "Sample_Summary.htm")
    end

    def to_json
      flowcell_data = []
      @flowcell.each_sample_with_lane do |sample, lane|
        sample.reads.each do |read|
          sample_read_data = data_for sample, read
          flowcell_data << sample_read_data
        end
      end
      flowcell_data
    end

    def data_for sample, read
      sample_data = {}

      if sample.barcode_type == :custom
        sample_data = get_custom_data sample, read
      else
        sample_data = get_casava_data sample, read
      end
      sample_data
    end

    def lims_data_for sample, read
      lims_data = {}
      lims_data["FCID"] = @flowcell.id
      lims_data["laneID"] = sample.lane
      lims_data["readNo"] = read
      lims_data
    end

    def get_custom_data sample, read
      barcode_filename = @flowcell.paths.custom_barcode_path_out(sample.lane.to_i)
      custom_data = {}
      lims_data = lims_data_for(sample,read)
      if File.exists? barcode_filename
        tab_parser = TabFileParser.new
        barcode_data = tab_parser.parse(barcode_filename)
        barcode_data.each do |barcode_line|
          if barcode_line["Barcode"] == sample.custom_barcode
            custom_data = barcode_line
            CUSTOM_TO_LIMS.each do |custom_key, lims_key|
              lims_data[lims_key] = custom_data[custom_key]
            end
            break
          end
        end
      end
      lims_data
    end

    def get_casava_data sample, read
      parser = CasavaOutputParser.new(@demultiplex_filename, @sample_summary_filename)
      casava_data = {}
      lims_data = lims_data_for(sample, read)
      casava_data = parser.data_for(sample, read)
      if casava_data.empty?
        puts "ERROR: sample report maker cannot find demultiplex data for #{sample.id}"
      else
        count = casava_data["# Reads"]
        # for paired-end reads, the casava output is the total number of reads for both
        # ends. So we divide by 2 to get the number of reads for individual reads.
        if sample.read_count == 2
          count = (count.to_f / 2).round.to_i.to_s
          casava_data["# Reads"] = count
        end

        # convert to lims names
        CASAVA_TO_LIMS.each do |casava_key, lims_key|
          lims_data[lims_key] = casava_data[casava_key]
        end
      end
      lims_data
    end
  end
end
