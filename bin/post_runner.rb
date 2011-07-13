#! /usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

require 'fileutils'

require 'sample_sheet'
require 'flowcell_data'
require 'emailer'
require 'solexa_logger'

class DistributionData
  def self.query_ngslims flowcell_id
    query_results = %x[perl #{SCRIPT_PATH}/ngsquery.pl fc_postRunArgs #{flowcell_id}]
    query_results.force_encoding("iso-8859-1")
    query_results.split("\t")
  end

  def self.distributions_for flowcell_id
    raw_data = query_ngslims flowcell_id

    distribution_paths = raw_data[0].split(":")
    distribution_lane_sets = raw_data[1].split(":")
    distribution_data = []
    distribution_lane_sets.each_with_index do |lane_set, index|
      lanes = lane_set.split(",")
      lanes.each do |lane|
        dist = {:lane => lane.to_i, :path => distribution_paths[index]}
        distribution_data << dist
      end
    end
    distribution_data
  end
end

class PostRunner
  attr_reader :flowcell_id
  attr_accessor :test

  def initialize fcid
    @flowcell_id = fcid
    @test = true
    @post_run_script = nil
  end

  def execute command
    log command
    system(command) unless @test
  end

  def log message
    puts message
    if @post_run_script and !@post_run_script.closed?
      @post_run_script << message << "\n"
    end
  end

  def status message
    log "# #{message}"
    SolexaLogger.log(@flowcell_id, message) unless @test
  end

  def check_exists files
    files = [files].flatten
    rtn = true
    files.each do |file|
      if !file or !File.exists?(file)
        log "# Error: file not found:#{file}."
        rtn = false unless @test
      end
    end
    rtn
  end

  def start_flowcell
    Emailer.email "starting post run for #{@flowcell_id}" unless @test
    status "postrun start"
    flowcell = Iluminati::FlowcellData.new @flowcell_id, @test

    @post_run_script_filename = File.join(flowcell.base_dir, "postrun_#{flowcell.flowcell_id}.sh")
    @post_run_script = File.new(@post_run_script_filename, 'w')
    flowcell
  end

  def stop_flowcell flowcell
    @post_run_script.close if @post_run_script
    qc_postrun_filename = File.join(flowcell.qc_dir, File.basename(@post_run_script_filename))
    execute "cp #{@post_run_script_filename} #{qc_postrun_filename}"
    Emailer.email "post run complete for #{@flowcell_id}" unless @test
    status "postrun done"
  end

  def run
    flowcell = start_flowcell
    distributions = DistributionData.distributions_for @flowcell_id

    run_unaligned flowcell, distributions

    run_aligned flowcell, distributions

    distribute_to_qcdata flowcell
    stop_flowcell flowcell
  end

  def run_unaligned flowcell, distributions
    status "processing unaligned"
    fastq_groups = group_fastq_files(flowcell.unaligned_project_dir,
                                     flowcell.fastq_combine_dir,
                                     flowcell.fastq_filter_dir)
    cat_files fastq_groups
    filter_fastq_files fastq_groups, flowcell.fastq_filter_dir

    status "distributing unaligned fastq.gz files"
    distribute_files fastq_groups, distributions
    run_unaligned_qc flowcell, distributions
  end

  def run_aligned flowcell, distributions
    status "processing export files"
    export_groups = group_export_files(flowcell.aligned_project_dir,
                                       flowcell.eland_combine_dir,
                                       flowcell.eland_combine_dir)
    cat_files export_groups

    status "distributing export files"
    distribute_files export_groups, distributions
    status "distributing aligned stats files"
    distribute_aligned_stats_files distributions, flowcell
  end

  def run_unaligned_qc flowcell, distributions
    status "running fastqc"
    run_fastqc flowcell.fastq_filter_dir

    ivc_file = File.join(flowcell.unaligned_stats_dir, "IVC.htm")
    convert_to_pdf ivc_file

    status "distributing unaligned stats directory"
    distribute_to_unique distributions, flowcell.unaligned_stats_dir
    status "distributing fastqc directory"
    distribute_to_unique distributions, flowcell.fastqc_dir
  end

  def distribute_to_qcdata flowcell
    status "distributing to qcdata"
    execute "mkdir -p #{flowcell.qc_dir}"
    distribution = {:path => flowcell.qc_dir}
    qc_files = ["InterOp", "RunInfo.xml", "Events.log", "Data/reports"]
    qc_paths = qc_files.collect {|qc_file| File.join(flowcell.base_dir, qc_file)}
    distribute_to_unique distribution, qc_paths
    distribute_to_unique distribution, flowcell.unaligned_stats_dir
    distribute_aligned_stats_files distribution, flowcell
    distribute_to_unique distribution, flowcell.fastqc_dir
  end

  def distribute_aligned_stats_files distribution, flowcell
    base_stats_files = ["Flowcell_Summary_*"]
    stats_files = ["Barcode_Lane_Summary.htm", "Sample_Summary.htm"]
    stats_paths = find_files_in(base_stats_files, flowcell.aligned_dir)
    stats_paths.concat(find_files_in(stats_files, flowcell.aligned_stats_dirs))

    distribute_to_unique distribution, stats_paths

  end

  def find_files_in file_matches, root_paths
    root_paths = [root_paths].flatten
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

  def convert_to_pdf input_file
    if check_exists(input_file)
      output_file = input_file.split(".")[0..-2].join(".") + ".pdf"
      execute "wkhtmltopdf #{input_file} #{output_file}"
    end
  end

  def distribute_files file_groups, distributions
    distributions.each do |distribution|
      log "# Creating directory #{distribution[:path]}"
      execute "mkdir -p #{distribution[:path]}"

      distribution_groups = file_groups.select {|g| g[:lane] == distribution[:lane]}
      distribution_groups.each do |group|
        present = check_exists(group[:filter_path])
        if present
          command = "cp #{group[:filter_path]} #{distribution[:path]}"
          execute command
        end
      end
    end
  end

  # only distribute once to each path in distributions
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

  def filter_fastq_files fastq_groups, output_path
    log "# Creating path: #{output_path}"
    execute "mkdir -p #{output_path}"

    filterer = File.join(SCRIPT_PATH, "fastq_filter.rb")
    fastq_groups.each do |group|
      command = "zcat #{group[:path]} | #{filterer} | gzip -c > #{group[:filter_path]}"
      execute command
    end
  end

  def group_fastq_files starting_path, output_path, filter_path
    execute "mkdir -p #{output_path}"

    fastq_files = Dir.glob(File.join(starting_path, "**", "*.fastq.gz"))
    raise "ERROR: no fastq files found in #{starting_path}" if fastq_files.empty?
    log "# #{fastq_files.size} fastq files found in #{starting_path}"

    fastq_file_data = get_file_data fastq_files, "\.fastq\.gz"

    fastq_groups = group_files fastq_file_data, output_path, filter_path
    fastq_groups
  end

  def group_export_files starting_path, output_path, filter_path
    execute "mkdir -p #{output_path}"

    export_files = Dir.glob(File.join(starting_path, "**", "*_export.txt.gz"))
    raise "ERROR: no export files found in #{starting_path}" if export_files.empty?
    log "# #{export_files.size} export files found in #{starting_path}"

    export_file_data = get_file_data export_files, "_export\.txt\.gz"
    options = {:prefix => "s_", :suffix => "_export.txt.gz"}
    export_groups = group_files export_file_data, output_path, filter_path, options
    export_groups
  end

  # runs fastqc on all relevant files in fastq_path
  # output is genearted fastq_path/fastqc
  def run_fastqc fastq_path
    cwd = Dir.pwd
    if check_exists(fastq_path)
      command = "cd #{fastq_path};"
      script = File.join(SCRIPT_PATH, "fastqc.pl")
      command += " #{script} -v --files \"*.fastq.gz\""
      execute command
      execute "cd #{cwd}"
    end
  end

  # actually combines the related fastq files
  # using cat
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

  # returns an array of hashes, one for each
  # new combined fastq file to be created
  # Each hash will have the name of the
  # combined fastq file and an Array of
  # paths that the group contains
  def group_files file_data, output_path, filter_path, options = {:prefix => "s_", :suffix => ".fastq.gz"}
    groups = {}
    file_data.each do |data|
      if data[:barcode] == "Undetermined"
        log "# Undetermined sample lane: #{data[:lane]} - name: #{data[:sample_name]}. Skipping"
        next
      end

      group_key = "#{options[:prefix]}#{data[:lane]}_#{data[:read]}_#{data[:barcode]}#{options[:suffix]}"
      if groups.include? group_key
        if groups[group_key][:sample_name] != data[:sample_name]
          raise "ERROR: sample names not matching #{group_key} - #{data[:path]}"
        end
        if groups[group_key][:lane] != data[:lane]
          raise "ERROR: lanes not matching #{group_key} - #{data[:path]}"
        end
        groups[group_key][:files] << data
      else
        group_path = File.join(output_path, group_key)
        group_filter_path = File.join(filter_path, group_key)
        groups[group_key] = {:group_name => group_key,
                             :path => group_path,
                             :filter_path => group_filter_path,
                             :sample_name => data[:sample_name],
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

  # returns Array of hashes for files in input
  # Hash includes sample_name, barcode, lane,
  # basename, and full path
  def get_file_data files, suffix_pattern = "\.fastq\.gz"

    $NAME_PATTERN = /(.*)_([ATCG]+|NoIndex|Undetermined)_L(\d{3})_R(\d)_(\d{3})#{suffix_pattern}/
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


if __FILE__ == $0
  flowcell_id = ARGV[0]
  test = ARGV[1]
  if flowcell_id
    runner = PostRunner.new flowcell_id
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
