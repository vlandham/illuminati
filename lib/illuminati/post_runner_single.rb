require 'parallel'
require 'illuminati/emailer'

SINGLE_BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
SINGLE_FILTER_SCRIPT = File.join(SINGLE_BASE_BIN_DIR, "fastq_filter.rb")

DISTRIBUTE_PROCESSES = 4

module Illuminati
  #
  # The most complicated and least well implemented of the Illuminati classes.
  # PostRunner is executed after the alignment step has completed. It Performs all the
  # steps necessary to convert the output of CASAVA into output we want to use and
  # ship that output to the proper places. Here's some of what PostRunner does:
  #
  # * Rename fastq.gz files
  # * Filter fastq.gz files
  # * Split lanes with custom barcodes
  # * Run fastqc on fastq.gz files
  # * Create Sample_Report.csv
  # * Distribute fastq.gz files to project directories
  # * Distribute qc / stats data to project directories
  # * Distribute qc / stats data to qcdata directory
  # * Rename export files
  # * Distribute export files to project directories
  #
  # The --steps option can be used to limit which steps are performed by the post run process.
  # Right now, check out the run method to see how this works.
  #
  # So there is a lot going down here. It uses Flowcell path data extensively for
  # determining what goes where. It also uses another class to get distribution data which
  # pulls this info from LIMS.
  #
  # The run method is the main starting point that kicks off all the rest of the process.
  # When done, the primary analysis pipeline should be considered complete.
  #
  class PostRunnerSingle
    attr_reader :flowcell
    attr_reader :options
    ALL_STEPS = %w{unaligned filter custom undetermined fastqc aligned stats report qcdata lims_upload lims_complete}
    DEFAULT_STEPS = %w{unaligned undetermined fastqc aligned stats report qcdata lims lims_upload lims_complete}

    #
    # New PostRunner instance
    #
    # == Parameters:
    # flowcell::
    #   Flowcell data instance. Passed in to help with testing.
    # options::
    #   Hash of options to configure runner.
    #   :test - is the runner in test mode?
    #
    def initialize flowcell, options = {}
      options = {:test => false, :steps => ALL_STEPS}.merge(options)

      options[:steps].each do |step|
        valid = true
        unless ALL_STEPS.include? step
          puts "ERROR: invalid step: #{step}"
          valid = false
        end

        if !valid
          puts "Valid steps: #{ALL_STEPS.join(", ")}"
          raise "Invalid Step"
        end
      end

      @flowcell = flowcell
      @options = options
      @post_run_script = nil
    end

    #
    # Helper method that executes a given string on the command line.
    # This should be used instead of calling system directly, as it also
    # deals with if we are in test mode or not.
    #
    def execute command
      log command
      system(command) unless @options[:test]
    end

    #
    # Poorly named. This adds a message to the script output file.
    # Also outputs message to standard out.
    #
    def log message
      puts message
      if @post_run_script and !@post_run_script.closed?
        @post_run_script << message << "\n"
      end
    end

    #
    # Poorly named. Uses the logger module to output the current
    # status of the post run process.
    #
    def status message
      log "# #{message}"
      SolexaLogger.log(@flowcell.paths.id, message) unless @options[:test]
    end

    #
    # Helper method to print a title section in the
    # post run output
    #
    def title message
      log "#########################"
      log "## #{message}"
      log "#########################"
    end

    #
    # Returns boolean if all files input exist.
    # Also logs missing files using log method
    #
    # == Parameters:
    # files::
    #   Array of file paths
    #
    def check_exists files
      files = [files].flatten
      rtn = true
      files.each do |file|
        if !file or !File.exists?(file)
          log "# Error: file not found:#{file}."
          rtn = false unless @options[:test]
        end
      end
      rtn
    end

    #
    # Startup tasks to begin post run.
    # Should be called by run, but not directly.
    #
    def start_flowcell
      Emailer.email "starting post run for #{@flowcell.paths.id}" unless @options[:test]
      status "postrun start"

      @post_run_script_filename = File.join(@flowcell.paths.base_dir, "postrun_#{@flowcell.paths.id}.sh")
      @post_run_script = File.new(@post_run_script_filename, 'w')
    end

    #
    # Teardown process of post run.
    # Should not be called externally.
    #
    def stop_flowcell
      @post_run_script.close if @post_run_script
      qc_postrun_filename = File.join(@flowcell.paths.qc_dir, File.basename(@post_run_script_filename))
      execute "cp #{@post_run_script_filename} #{qc_postrun_filename}"
      Emailer.email "post run complete for #{@flowcell.paths.id}" unless @options[:test]
      status "postrun done"
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

      if steps.include? "custom"
        process_custom_barcode_reads distributions
        Emailer.email "UNDETERMINED step finished for #{@flowcell.paths.id}" unless @options[:test]
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

      if steps.include? "lims_upload"
        upload_lims
      end

      if steps.include? "lims_complete"
        complete_lims
      end

      stop_flowcell
    end

    #
    # Executes commands related to fastq.gz files including
    # filtering them and distributing them.
    #
    def process_unaligned_reads distributions
      status "processing unaligned"
      steps = @options[:steps]
      fastq_groups = group_fastq_files(@flowcell.paths.unaligned_project_dir,
                                       @flowcell.paths.fastq_combine_dir)
      unless @options[:only_distribute]
        cat_files fastq_groups
      end

      if steps.include? "filter"
        status "filtering unaligned fastq.gz files"
        unless @options[:only_distribute]
          fastq_groups = filter_fastq_files(fastq_groups, @flowcell.paths.fastq_filter_dir)
        end
      end

      unless @options[:no_distribute]
        status "distributing unaligned fastq.gz files"
        distribute_files fastq_groups, distributions
      end
    end


    def process_custom_barcode_reads distributions
      status "processing custom barcode reads"
      fastq_groups = group_fastq_files(@flowcell.paths.unaligned_project_dir,
                                       @flowcell.paths.fastq_combine_dir)
      custom_barcode_files = split_custom_barcodes fastq_groups
      distribute_files(custom_barcode_files, distributions) unless custom_barcode_files.empty?
    end

    #
    # Executes commands related to export files, including renaming them
    # and distributing them to project directories.
    #
    def run_aligned distributions
      status "processing export files"
      aligned_project_dir = get_aligned_project_dir
      export_groups = group_export_files(aligned_project_dir,
                                         @flowcell.paths.eland_combine_dir)
      unless @options[:only_distribute]
        cat_files export_groups
      end

      status "distributing export files"
      distribute_files export_groups, distributions
    end

    def get_aligned_project_dir
      project_dir = ""
      dirs = @flowcell.paths.aligned_project_dirs
      if dirs.size == 0
        puts "ERROR: No Aligned Project dir found for #{@flowcell.id}"
        raise "NO ALIGNED PROJECT DIR"
      elsif dirs.size == 1
        project_dir = dirs.shift
      else
        projects_with_samples = []
        dirs.each do |dir|
          sample_dirs = Dir.glob(File.join(dir, "Sample_*"))
          if sample_dirs.size > 0
            projects_with_samples << dir
          end
        end

        if projects_with_samples.size == 0
          puts "ERROR: No Sample Directories Found in:"
          puts dirs.join(", ")
          raise "NO SAMPLES IN PROJECT DIR"
        elsif projects_with_samples.size == 1
          project_dir = projects_with_samples.shift
          puts "WARNING: All Sample Dirs in #{project_dir}"
        else
          final_project_dir = File.join(@flowcell.paths.aligned_dir, "Project_#{@flowcell.id}")
          puts "WARNING: Combining export files in #{final_project_dir}"
          system("mkdir -p #{final_project_dir}")
          projects_with_samples.each do |sample_project|
            sample_dirs = Dir.glob(File.join(sample_project, "Sample_*"))
            sample_dirs.each do |sample_dir|
              system("mv #{sample_dir} #{final_project_dir}")
            end
          end
          project_dir = final_project_dir
        end
        puts project_dir
        project_dir
      end

    end

    #
    # Calls SampleReportMaker to create Sample_Report.csv
    #
    def create_sample_report
      status "creating sample_report"
      sample_report = SampleReportMaker.make(@flowcell)
      File.open(@flowcell.paths.sample_report_path, 'w') do |file|
        file.puts sample_report
      end
    end

    #
    # Distriubutes Sample_Report.csv to project directories
    #
    def distribute_sample_report distributions
      status "distributing sample_report"
      distribute_to_unique distributions, @flowcell.paths.sample_report_path
    end

    #
    # Sends flowcell stats to Lims
    # and marks flowcell as complete
    #
    def upload_lims
      status "uploading to lims"

      notifier = Illuminati::LimsNotifier.new(@flowcell)
      notifier.upload_to_lims
    end

    def complete_lims
      status "completing lims"

      notifier = Illuminati::LimsNotifier.new(@flowcell)
      notifier.complete_analysis
    end

    #
    # Executes all functionality related to splitting lanes with customm
    # barcodes into separate fastq.gz files. Should be executed before
    # running fastqc to get separate results for each barcoded sample.
    #
    def split_custom_barcodes groups
      custom_barcode_data = []
      groups.each do |sample_data|
        barcode_file_path = @flowcell.paths.custom_barcode_path(sample_data[:lane])
        if File.exists?(barcode_file_path)
          orginal_fastq_path = sample_data[:path]
          fastq_base_dir = File.dirname(orginal_fastq_path)
          file_prefix = File.join(fastq_base_dir, "s_#{sample_data[:lane]}_#{sample_data[:read]}_")
          file_suffix = ".fastq"

          command = "zcat #{orginal_fastq_path} |"
          command += " fastx_barcode_splitter.pl --bcfile #{barcode_file_path}"
          command += " --bol --prefix \"#{file_prefix}\""
          command += " --suffix \"#{file_suffix}\""
          command += " > #{@flowcell.paths.custom_barcode_path_out(sample_data[:lane])} 2>&1"
          execute command

          unmatched = Dir.glob("#{file_prefix}unmatched#{file_suffix}")
          unmatched.each do |unmatched_filename|
            undetermined_filename = "#{file_prefix}Undetermined#{file_suffix}"
            execute "mv #{unmatched_filename} #{undetermined_filename}"
          end

          uncompressed_fastq_files = Dir.glob("#{file_prefix}*#{file_suffix}")
          compressed_fastq_files = []
          uncompressed_fastq_files.each do |uncompressed_fastq_file|
            execute "gzip -f #{uncompressed_fastq_file}"
            compressed_fastq_files << uncompressed_fastq_file + ".gz"
          end

          compressed_fastq_files.each do |barcode_file_path|
            barcode_file_name = File.basename(barcode_file_path)
            custom_barcode_hash = {:lane => sample_data[:lane], :read => sample_data[:read],
                                   :path => barcode_file_path, :group_name => barcode_file_name}
            custom_barcode_data << custom_barcode_hash
          end
        end
      end
      custom_barcode_data
    end

    #
    # Collects and distributes all the files needed to go to the qcdata
    # directory.
    #
    def distribute_to_qcdata
      status "distributing to qcdata"
      execute "mkdir -p #{@flowcell.paths.qc_dir}"
      distribution = {:path => @flowcell.paths.qc_dir}
      qc_files = ["InterOp", "RunInfo.xml", "Events.log", "Data/reports"]
      qc_paths = qc_files.collect {|qc_file| File.join(@flowcell.paths.base_dir, qc_file)}
      distribute_to_unique distribution, qc_paths
      distribute_to_unique distribution, @flowcell.paths.unaligned_stats_dir
      distribute_custom_stats_files distribution
      distribute_to_unique distribution, @flowcell.paths.fastqc_dir
      distribute_sample_report distribution
    end

    #
    # Collects the stats files needed and distributes them
    #
    def create_custom_stats_files
      new_stats_dir_path = @flowcell.paths.custom_stats_dir
      execute "mkdir -p #{new_stats_dir_path}"

      ivc_file = File.join(@flowcell.paths.unaligned_stats_dir, "IVC.htm")
      convert_to_pdf ivc_file
      ivc_pdf = find_files_in "IVC.pdf", @flowcell.paths.unaligned_stats_dir
      copy_files ivc_pdf, new_stats_dir_path

      demultiplex_stats_file = find_files_in "Demultiplex_Stats.htm", @flowcell.paths.unaligned_stats_dir
      copy_files demultiplex_stats_file, new_stats_dir_path

      stats_files = ["Barcode_Lane_Summary.htm", "Sample_Summary.htm"]
      if @flowcell.paths.aligned_project_dir and File.exists?(@flowcell.paths.aligned_project_dir)
        summary_files = find_files_in(stats_files, @flowcell.paths.aligned_stats_dir)
        copy_files summary_files, new_stats_dir_path
      end
    end

    def distribute_custom_stats_files distribution
      status "distributing aligned stats files"
      distribute_to_unique distribution, @flowcell.paths.custom_stats_dir
    end

    #
    # Helper method to copy files from one location to another
    #
    def copy_files file_paths, destination_path
      files = [file_paths].flatten
      files.each do |file_path|
        execute "cp #{file_path} #{destination_path}"
      end
    end

    #
    # Helper method to return an array of files that match
    # a particular pattern and are rooted in one or more places.
    # Both inputs are arrays, but can also be individual strings.
    #
    def find_files_in file_matches, root_paths
      root_paths = [root_paths].flatten.compact
      file_matches = [file_matches].flatten.compact
      returned_paths = []
      root_paths.each do |root_path|
        matched_paths = file_matches.collect do |file|
          matched_files = Dir.glob(File.join(root_path, file))
          matched_files.size > 0 ? matched_files[0] : nil
        end
        matched_paths.compact
        returned_paths.concat matched_paths
      end
      returned_paths
    end

    #
    # Helper method to call wkhtmltopdf on an input file.
    # No error checking is done.
    #
    def convert_to_pdf input_file
      if check_exists(input_file)
        output_file = input_file.split(".")[0..-2].join(".") + ".pdf"
        execute "wkhtmltopdf #{input_file} #{output_file}"
      end
    end

    #
    # Given a set of file groups and an array of distribution paths,
    # this method copies the appropriate files to the appropriate
    # project directories.
    # By appropriate, we mean that the lane in the file group matches
    # the lane indicated in the distributions.
    #
    def distribute_files file_groups, distributions
      distributions.each do |distribution|
        log "# Creating directory #{distribution[:path]}"
        execute "mkdir -p #{distribution[:path]}"
        distribution_groups = file_groups.select {|g| g[:lane].to_i == distribution[:lane].to_i}
        log "# Found #{distribution_groups.size} groups"
        Parallel.each(distribution_groups, :in_processes => DISTRIBUTE_PROCESSES) do |group|
          present = check_exists(group[:path])
          if present
            command = "cp #{group[:path]} #{distribution[:path]}"
            execute command
          end
        end
      end
    end

    #
    # Given an array of distributions and an array of file paths
    # this method copies each file in the file paths to each distribution
    # but ensures this process only occurs once to avoid copying to the same
    # project directory mulitiple times.
    #
    def distribute_to_unique distributions, full_source_paths
      distributions = [distributions].flatten
      full_source_paths = [full_source_paths].flatten
      full_source_paths.each do |full_source_path|
        if check_exists(full_source_path)
          already_distributed = []
          source_path = File.basename(full_source_path)

          distributions.each do |distribution|
            full_distribution_path = File.join(distribution[:path], source_path)
            unless already_distributed.include? full_distribution_path
              already_distributed << full_distribution_path

              distribution_dir = File.dirname(full_distribution_path)
              execute "mkdir -p #{distribution_dir}" unless File.exists? distribution_dir

              if File.directory? full_source_path
                log "# Creating directory #{full_distribution_path}"
                execute "mkdir -p #{full_distribution_path}"
              end
              command = "cp -r #{full_source_path} #{distribution_dir}"
              execute command
            end
          end
        end
      end
    end

    def process_undetermined_reads distributions
      status "process undetermined unaligned reads"
      starting_path = @flowcell.paths.unaligned_undetermined_dir
      output_path = @flowcell.paths.unaligned_undetermined_combine_dir
      options = {:prefix => "s_", :suffix => ".fastq.gz", :exclude_undetermined => false}

      fastq_file_groups = group_fastq_files starting_path, output_path, options

      unless @options[:only_distribute]
        cat_files fastq_file_groups
      end

      unless @options[:no_distribute]
        status "distributing unaligned undetermined fastq.gz files"
        distribute_files fastq_file_groups, distributions
      end
    end

    def fastq_search_path
      "**/*.fastq.gz"
    end

    #
    # Gets grouping data for fastq.gz files
    #
    def group_fastq_files starting_path, output_path, options = {:prefix => "s_", :suffix => ".fastq.gz", :exclude_undetermined => true}
      execute "mkdir -p #{output_path}"
      fastq_groups = []

      fastq_files = Dir.glob(File.join(starting_path, fastq_search_path))
      if fastq_files.empty?
        log "# ERROR: no fastq files found in #{starting_path}" if fastq_files.empty?
      else
        log "# #{fastq_files.size} fastq files found in #{starting_path}"
        fastq_file_data = get_file_data fastq_files, "\.fastq\.gz"
        fastq_groups = group_files fastq_file_data, output_path, options
      end
      fastq_groups
    end

    #
    # Gets grouping data for export files
    #
    def group_export_files starting_path, output_path
      execute "mkdir -p #{output_path}"

      export_files = Dir.glob(File.join(starting_path, "**", "*_export.txt.gz"))
      raise "ERROR: no export files found in #{starting_path}" if export_files.empty?
      log "# #{export_files.size} export files found in #{starting_path}"

      export_file_data = get_file_data export_files, "_export\.txt\.gz"
      options = {:prefix => "s_", :suffix => "_export.txt.gz", :exclude_undetermined => true}
      export_groups = group_files export_file_data, output_path, options
      export_groups
    end

    #
    # Runs fastqc on all relevant files in fastq_path
    # output is genearted fastq_path/fastqc
    #
    def run_fastqc fastq_path
      status "running fastqc"
      cwd = Dir.pwd
      if check_exists(fastq_path)
        command = "cd #{fastq_path};"
        script = Illuminati::ScriptPaths.fastqc_script
        command += " #{script} -v --files \"*.fastq.gz\""
        execute command
        execute "cd #{cwd}"
      end
    end

    #
    # Actually combines the related fastq files
    # using cat.
    #
    def cat_files file_groups
      file_groups.each do |group|
        check_exists(group[:paths])
        # this is the Illumina recommended approach to combining these fastq files.
        # See the Casava 1.8 Users Guide for proof
        files_list = group[:paths].join(" ")
        command = "cat #{files_list} > #{group[:path]}"
        execute command
      end
    end

    #
    # Method to strip out reads in fastq.gz files that do not
    # pass filter. Filtered files are copied to the :filter_path
    # in the groups hash.
    #
    def filter_fastq_files fastq_groups, output_path

      log "# Creating path: #{output_path}"
      execute "mkdir -p #{output_path}"

      fastq_groups.each do |group|
        group_filter_path = File.join(output_path, group[:group_name])
        command = "zcat #{group[:path]} | #{FILTER_SCRIPT} | gzip -c > #{group_filter_path}"
        execute command
        group[:path] = group_filter_path
      end
      fastq_groups
    end

    #
    # Returns an array of hashes, one for each
    # new combined fastq file to be created
    # Each hash will have the name of the
    # combined fastq file and an Array of
    # paths that the group contains
    #
    def group_files file_data, output_path, options = {:prefix => "s_", :suffix => ".fastq.gz", :exclude_undetermined => true}
      groups = {}
      file_data.each do |data|
        if data[:barcode] == "Undetermined" and options[:exclude_undetermined]
          log "# Undetermined sample lane: #{data[:lane]} - name: #{data[:sample_name]}. Skipping"
          next
        end

        group_key = name_for_data data, options

        if groups.include? group_key
          if groups[group_key][:sample_name] != data[:sample_name]
            raise "ERROR: sample names not matching #{group_key} - #{data[:path]}:#{data[:sample_name]}vs#{groups[group_key][:sample_name]}"
          end
          if groups[group_key][:lane] != data[:lane]
            raise "ERROR: lanes not matching #{group_key} - #{data[:path]}"
          end
          groups[group_key][:files] << data
        else
          group_path = File.join(output_path, group_key)
          groups[group_key] = {:group_name => group_key,
                               :path => group_path,
                               :sample_name => data[:sample_name],
                               :read => data[:read],
                               :lane => data[:lane],
                               :files => [data]
          }
        end
      end

      # sort based on read set
      groups.each do |key, group|
        group[:files] = group[:files].sort {|x,y| x[:set] <=> y[:set]}
        group[:paths] = group[:files].collect {|data| data[:path]}
      end
      groups.values
    end

    def name_for_data data, options = {:prefix => "s_", :suffix => ".fastq.gz"}
      "#{options[:prefix]}#{data[:lane]}_#{data[:read]}_#{data[:barcode]}#{options[:suffix]}"
    end

    #
    # Returns Array of hashes for files in input
    # Hash includes sample_name, barcode, lane,
    # basename, and full path
    #
    def get_file_data files, suffix_pattern = "\.fastq\.gz"
      files = [files].flatten

      $NAME_PATTERN = /(.*)_([ATCGN]+|NoIndex|Undetermined)_L(\d{3})_R(\d)_(\d{3})#{suffix_pattern}/
      # 1_ACTTGA_ACTTGA_L001_R1_002.fastq.gz
      # $1 = "1_ACTTGA"
      # $2 = "ACTTGA"
      # $3 = "001"
      # $4 = "1"
      # $5 = "002"

      file_data = files.collect do |file|
        base_name = File.basename(file)
        match = base_name =~ $NAME_PATTERN
        raise "ERROR: #{file} does not match expected file name pattern" unless match
        data = {:name => base_name, :path => file,
                :sample_name => $1, :barcode => $2,
                :lane => $3.to_i, :read => $4.to_i, :set => $5.to_i}
        data
      end
      file_data
    end
  end
end
