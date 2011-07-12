
require 'illuminati/constants'

class FlowcellData
  attr_reader :flowcell_id

  def initialize flowcell_id, testing = false
    @flowcell_id = flowcell_id
    @test = testing
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

  def base_dir
    path = File.join(FLOWCELL_PATH_BASE, "*#{@flowcell_id}")
    paths = Dir.glob(path)
    if paths.size < 1
      puts "ERROR: no flowcell directory found for #{@flowcell_id}"
      puts "ERROR: search path: #{path}"
      raise "no flowcell path" unless @test
    elsif paths.size > 1
      puts "ERROR: multiple flowcell directories found for #{@flowcell_id}"
      puts "ERROR: number of paths found: #{paths.size}"
      raise "too many flowcell paths" unless @test
    end
    File.expand_path(paths[0])
  end

  def base_name
    File.basename(base_dir)
  end

  def qc_dir
    File.join(QC_PATH, base_name)
  end

  def base_calls_dir
    File.join(base_dir, BASECALLS_PATH)
  end

  def unaligned_dir
    File.join(base_dir, "Unaligned")
  end

  def unaligned_project_dir
    single_directory_in unaligned_dir, PROJECT_PATTERN
  end

  def unaligned_stats_dir
    single_directory_in unaligned_dir, FASTQ_STATS_PATTERN
  end

  def fastq_combine_dir
    File.join(unaligned_dir, FASTQ_COMBINE_PATH)
  end

  def fastq_filter_dir
    File.join(unaligned_dir, FASTQ_FILTER_PATH)
  end

  def fastqc_dir
    File.join(fastq_filter_dir, "fastqc")
  end

  def aligned_dir
    File.join(base_dir, "Aligned")
  end

  def aligned_project_dir
    single_directory_in aligned_dir, PROJECT_PATTERN
  end

  def eland_combine_dir
    File.join(aligned_dir, ELAND_COMBINE_PATH)
  end

  def aligned_stats_dirs
    stats_pattern = File.join(PROJECT_PATTERN, ELAND_STATS_PATTERN)
    directories_in aligned_dir, stats_pattern
  end

  def script_path
    script_file_name = "#{ADMIN_PATH}/#{@flowcell_id}.sh"
  end

  def custom_barcode_path lane
    if lane < 1 or lane > 8
      puts "ERROR: invalid lane number #{lane}"
      raise "invalid lane"
    end

    File.join(base_dir, "custom_barcodes_#{lane}.txt")
  end

  def info_path
    File.join(base_dir, "flowcell_info.yaml")
  end

  def single_directory_in base_path, directory_pattern
    input_paths = directories_in base_path, directory_pattern
    if input_paths.size > 1
      puts "ERROR: multiple paths found: \n#{input_paths.inspect}"
      raise "multiple paths found" unless @test
    end
    input_paths[0]
  end

  def directories_in base_path, directory_pattern
    input_paths = Dir.glob(File.join(base_path, directory_pattern))
    if input_paths.size < 1
      puts "ERROR: no paths found at #{base_path}/#{directory_pattern}"
      raise "no path found" unless @test
    end
    input_paths
  end
end
