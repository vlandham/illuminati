
require 'illuminati/constants'

module Illuminati
  #
  # Serves as a central repository for all the path information for a particular
  # flowcell. Most of the rest of the knowledge we have of a flowcell is contained
  # in FlowcellRecord. This class really focuses on paths.
  #
  class FlowcellPaths
    attr_reader :flowcell_id, :test, :paths
    alias :id :flowcell_id

    #
    # Create new instance.
    #
    # == Parameters:
    # flowcell_id::
    #   Id of flowcell we want path info about.
    #
    # testing::
    #   If true, exceptions will not be raised for missing critical files / folders.
    def initialize flowcell_id, testing = false, paths = Paths
      @flowcell_id = flowcell_id
      @test = testing
      @paths = paths
    end

    def to_h
      data_headers = [:base_dir, :unaligned_dir, :aligned_dir, :qc_dir]
      hash = Hash.new
      data_headers.each do |header|
        if self.respond_to?(header)
          hash[header] = self.send(header)
        end
      end
      hash
    end

    #
    # The base directory is the root directory for this flowcell.
    # This means for us that it is the /solexa/*[FLOWCELL_ID] path.
    #
    def base_dir
      path = File.join(@paths.base, "*#{@flowcell_id}")
      paths = Dir.glob(path)
      if paths.size < 1
        puts "ERROR: no flowcell directory found for #{@flowcell_id}"
        puts "ERROR: search path: #{path}"
        raise "no flowcell path #{path}" unless @test
      elsif paths.size > 1
        puts "ERROR: multiple flowcell directories found for #{@flowcell_id}"
        puts "ERROR: number of paths found: #{paths.size}"
        raise "too many flowcell paths" unless @test
      end
      File.expand_path(paths[0])
    end

    #
    # Returns the directory name of the flowcell without the /solexa prepending it.
    #
    def base_name
      File.basename(base_dir)
    end

    #
    # Quality Control diretory where qc files get stored.
    #
    def qc_dir
      File.join(QC_PATH, base_name)
    end

    #
    # The Basecalls diretory for this flowcell.
    #
    def base_calls_dir
      File.join(base_dir, BASECALLS_PATH)
    end

    #
    # The location where fastq.gz files will be
    # placed by the CASAVA 1.8 pipeline.
    #
    def unaligned_dir
      File.join(base_dir, "Unaligned")
    end

    #
    # This is where CASAVA 1.8 puts
    # the truseq reads that don't match an index.
    #
    def unaligned_undetermined_dir
      File.join(unaligned_dir, "Undetermined_indices")
    end

    #
    # This is where Illuminati puts joined undetermined fastq files
    #
    def unaligned_undetermined_combine_dir
      File.join(unaligned_dir, FASTQ_UNDETERMINED_COMBINE_PATH)
    end

    #
    # The project directory inside the unaligned directory.
    # This is where CASAVA works, and where the fastq.gz files
    # it creates are originally located.
    #
    def unaligned_project_dir
      single_directory_in unaligned_dir, PROJECT_PATTERN
    end

    #
    # The path to the directory where unaligned stats files are
    # kept. This is the Basecall_Stats directory.
    #
    def unaligned_stats_dir
      single_directory_in unaligned_dir, FASTQ_STATS_PATTERN
    end

    #
    # Where fastq files will be concatentated by Illuminati.
    #
    def fastq_combine_dir
      File.join(unaligned_dir, FASTQ_COMBINE_PATH)
    end

    #
    # Where fastq files that have reads that don't pass filter will
    # be put by Illuminati.
    #
    def fastq_filter_dir
      File.join(unaligned_dir, FASTQ_FILTER_PATH)
    end

    #
    # Location of the fastqc directory that will be created by
    # running fastqc script on filtered fastq.gz files.
    #
    def fastqc_dir
      File.join(fastq_combine_dir, "fastqc")
    end

    #
    # Directory used by CASAVA 1.8 to put export files.
    #
    def aligned_dir
      File.join(base_dir, "Aligned")
    end

    #
    # Project directory where CASAVA works and where it places
    # its original export files.
    #
    def aligned_project_dir
      single_directory_in aligned_dir, PROJECT_PATTERN
    end

    def aligned_project_dirs
      directories_in aligned_dir, PROJECT_PATTERN
    end

    #
    # Location that Illuminati will use to rename and combine
    # export files.
    #
    def eland_combine_dir
      File.join(aligned_dir, ELAND_COMBINE_PATH)
    end

    #
    # Technically, multiple project directories might exist, and
    # thus multiple stats directories in them. However, the
    # way we are using things, this will always return an
    # array of only one directory.
    # Use aligned_stats_dir to access that path directly.
    #
    def aligned_stats_dirs
      stats_pattern = File.join(PROJECT_PATTERN, ELAND_STATS_PATTERN)
      directories_in aligned_dir, stats_pattern
    end

    #
    # Location CASAVA will use to put stats files for the alignment process.
    #
    def aligned_stats_dir
      stats_pattern = File.join(PROJECT_PATTERN, ELAND_STATS_PATTERN)
      single_directory_in aligned_dir, stats_pattern
    end

    #
    # Location we will use to compile our custom stats files
    #
    def custom_stats_dir
      File.join(aligned_dir, "Summary_Stats_#{id}")
    end

    #
    # Location to put scripts generated by the startup.rb command.
    # Probably should not be here.
    #
    def script_path
      script_file_name = "#{ADMIN_PATH}/#{@flowcell_id}.sh"
    end

    #
    # For a given lane, return a path to put custom barcode files in.
    # These files are used by fastx_barcode_splitter.pl.
    #
    def custom_barcode_path lane
      if lane < 1 or lane > 8
        puts "ERROR: invalid lane number #{lane}"
        raise "invalid lane"
      end
      File.join(base_dir, "custom_barcodes_#{lane}.txt")
    end

    #
    # Path for each lane's fastx barcode splitting output.
    # Retained to grab the count data from it.
    # LIMITATION: this won't work for paired-end custom barcoded reads.
    # FIXME: add read to output path.
    #
    def custom_barcode_path_out lane
      custom_barcode_path(lane) + ".out"
    end

    #
    # Path for the sample report file
    #
    def sample_report_path
      File.join(base_dir, "Sample_Report.csv")
    end

    def qsub_db_path
      File.join(base_dir, "qsub_db")
    end

    #
    # unused
    #
    def info_path
      File.join(base_dir, "flowcell_info.yaml")
    end

    #
    # Helper method to get one directory in a base directory.
    # Raises exception if multiple matching directories are found.
    #
    def single_directory_in base_path, directory_pattern
      input_paths = directories_in base_path, directory_pattern
      if input_paths.size > 1
        puts "ERROR: multiple paths found: \n#{input_paths.inspect}"
        #raise "multiple paths found" unless @test
      end
      input_paths[0]
    end

    #
    # Helper method that returns all directories matching a pattern
    # that are rooted in a base path.
    #
    def directories_in base_path, directory_pattern
      input_paths = Dir.glob(File.join(base_path, directory_pattern))
      if input_paths.size < 1
        puts "ERROR: no paths found at #{base_path}/#{directory_pattern}"
        #raise "no path found" unless @test
      end
      input_paths
    end
  end
end
