require 'illuminati/post_runner'

module Illuminati
  class MiseqPostRunner < PostRunner
    DEFAULT_STEPS = %w{unaligned fastqc}
    def initialize flowcell, options = {}
      super(flowcell, options)
    end

    #
    # Main entry point to PostRunner. Starts post run process and executes all
    # required steps to getting data and files in to the way we want them.
    #
    def run
      start_flowcell
      distributions = []

      unless @options[:no_distribute]
        distributions = @flowcell.external_data.distributions_for @flowcell.id
      end

      steps = @options[:steps]
      status "running steps: #{steps.join(", ")}"

      if steps.include? "unaligned"
        # unaligned dir
        process_unaligned_reads distributions
        Emailer.email "UNALIGNED step finished for #{@flowcell.paths.id}" unless @options[:test]
      end

      if steps.include? "undetermined"
        process_undetermined_reads distributions
        Emailer.email "UNDETERMINED step finished for #{@flowcell.paths.id}" unless @options[:test]
      end

      if steps.include? "fastqc"
        unless @options[:only_distribute]
          run_fastqc @flowcell.paths.fastq_combine_dir
        end
        distribute_to_unique distributions, @flowcell.paths.fastqc_dir
        Emailer.email "FASTQC step finished for #{@flowcell.paths.id}" unless @options[:test]
      end

      if steps.include? "aligned"
        run_aligned distributions
        Emailer.email "ALIGNED step finished for #{@flowcell.paths.id}" unless @options[:test]
      end

      if steps.include? "stats"
        create_custom_stats_files
        distribute_custom_stats_files distributions
      end

      if steps.include? "report"
        create_sample_report
        distribute_sample_report distributions
      end

      if steps.include? "qcdata"
        distribute_to_qcdata
      end

      if steps.include? "lims"
        notify_lims
      end

      stop_flowcell
    end

    def get_sample_sheet_data
      sample_sheet_filename = File.join(@flowcell.paths.unaligned_dir, "SampleSheet.csv")
      if !File.exists?(sample_sheet_filename)
        puts "ERROR: cannot find sample sheet at #{sample_sheet_filename}"
        raise "no_sample_sheet"
      end
      data = SampleSheetParser.data_for(sample_sheet_filename)
      data
    end

    #
    # Returns Array of hashes for files in input
    # Hash includes sample_name, barcode, lane,
    # basename, and full path
    #
    def get_file_data files, suffix_pattern = "\.fastq\.gz"
      files = [files].flatten

      $NAME_PATTERN = /(.*)_S(\d+)_L(\d{3})_R(\d)_(\d{3})#{suffix_pattern}/
      # L1401_S1_L001_R1_001.fastq.gz
      # $1 = "L1401"
      # $2 = "1"
      # $3 = "001"
      # $4 = "1"
      # $5 = "001"

      sample_sheet_data = get_sample_sheet_data()


      file_data = files.collect do |file|
        base_name = File.basename(file)
        match = base_name =~ $NAME_PATTERN
        raise "ERROR: #{file} does not match expected file name pattern" unless match
        data = {:name => base_name, :path => file,
                :sample_name => $1, 
                :lane => $3.to_i, :read => $4.to_i, :set => $5.to_i}
        barcode = sample_sheet_data["samples"][$2.to_i - 1]["index"]

        if !(barcode =~ /([ATCGN]+|NoIndex|Undetermined)/)
          raise "ERRROR: invalid barcode for sample: #{barcode}"
        end
        data[:barcode] = barcode

        puts data.inspect
        data
      end
      file_data
    end
  end
end
