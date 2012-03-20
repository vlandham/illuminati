require 'json'

require 'illuminati/flowcell_record'
require 'illuminati/tab_file_parser'
require 'illuminati/casava_output_parser'

module Illuminati

  class LimsNotifier
    TEMP_JSON_FILE_NAME = "lims_data.json"

    def initialize flowcell
      @view = LimsUploadView.new(flowcell)
      @flowcell = flowcell
    end

    def upload_to_lims
      data = @view.to_json

      json_filename = File.join(@flowcell.paths.base_dir, TEMP_JSON_FILE_NAME)

      File.open(json_filename, 'w') do |file|
        file.puts(data)
      end
      perl_script = Illuminati::ScriptPaths.lims_upload_script
      command = "#{perl_script} #{json_filename}"
      puts command
      system(command)
    end

    def complete_analysis
      perl_script = Illuminati::ScriptPaths.lims_complete_script
      command = "#{perl_script} #{@flowcell.id}"
      system(command)
    end
  end

  #
  # Similar to SampleReportMaker - parses output files
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
      @demultiplex_filename = ""
      if @flowcell.paths.unaligned_stats_dir
        @demultiplex_filename = File.join(@flowcell.paths.unaligned_stats_dir, "Demultiplex_Stats.htm")
      else
        puts "ERROR: No Unaligned Stats Dir found"
        puts "Expected: #{@flowcell.paths.unaligned_stats_dir}"
      end

      @sample_summary_filenames = []
      if @flowcell.paths.aligned_stats_dirs
        @sample_summary_filenames = @flowcell.paths.aligned_stats_dirs.collect {|dir| File.join(dir, "Sample_Summary.htm") }
      else
        puts "ERROR: No Aligned Stats Dir found"
        puts "Expected: #{@flowcell.paths.aligned_stats_dir}"
      end
    end


    def to_json
      flowcell_data = []
      custom_barcoded_lanes_seen = []
      @flowcell.each_sample_with_lane do |sample, lane|
        sample.reads.each do |read|
          send = true

          # only send data for custom barcoded lanes once
          if sample.barcode_type == :custom
            if !custom_barcoded_lanes_seen.include? sample.lane
              custom_barcoded_lanes_seen << sample.lane
            else
              send = false
            end
          end

          if send
            sample_read_data = data_for sample, read
            flowcell_data << sample_read_data
          end
        end
      end
      flowcell_data.to_json
    end

    def data_for sample, read
      sample_data = {}

      #if sample.barcode_type == :custom
      #  sample_data = get_custom_data sample, read
      #else
        sample_data = get_casava_data sample, read
      #end
      sample_data
    end

    def lims_data_for sample, read
      lims_data = {}
      lims_data["FCID"] = @flowcell.id
      lims_data["laneID"] = sample.lane
      lims_data["readNo"] = read

      lims_data["index"] = sample.raw_barcode unless sample.raw_barcode == ""

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
      parser = CasavaOutputParser.new(@demultiplex_filename, @sample_summary_filenames)
      casava_data = {}
      lims_data = lims_data_for(sample, read)
      casava_data = parser.data_for(sample, read)
      if casava_data.empty?
        puts "ERROR: sample report maker cannot find demultiplex data for #{sample.id}"
      else
        count = casava_data["# Reads"]
        # for paired-end reads, the casava output is the total number of reads for both
        # ends. So we divide by 2 to get the number of reads for individual reads.

        # if sample.read_count == 2
        #   count = (count.to_f / 2).round.to_i.to_s
        #   casava_data["# Reads"] = count
        # end

        # convert to lims names
        CASAVA_TO_LIMS.each do |casava_key, lims_key|
          lims_data[lims_key] = casava_data[casava_key]
        end
      end
      lims_data
    end
  end
end
