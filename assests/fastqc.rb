
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

process_index = ENV["SGE_TASK_ID"].to_i - 1

path = ARGV[0]

command = "cd #{path};"
script = Illuminati::ScriptPaths.fastqc_script
command += " #{script} -v --files \"*.fastq.gz\""

puts command
`#{command}`


