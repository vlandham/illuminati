
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'pfastqc/start'

process_index = ENV["SGE_TASK_ID"].to_i - 1

FASTQC_PATH = `which fastqc`.chomp

fastq_directory = ARGV[0]

if !File.exists? fastq_directory
  puts "ERROR: fastq directory not found: #{fastq_directory}."
  exit(1)
end


starter = PFastqc::Start.new(FASTQC_PATH)
waiton_task = starter.run(fastq_directory)


