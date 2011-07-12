#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
ALIGN_SCRIPT = File.join(BASE_BIN_DIR, "align_runner.rb")
CONFIG_SCRIPT = File.join(BASE_BIN_DIR, "config_maker.rb")

flowcell_id = ARGV[0]

if flowcell_id
	puts "Flowcell ID: #{flowcell_id}"
else
	puts "ERROR: no flow cell ID provided"
	exit
end

module Illuminati

class ScriptWritter
  def initialize filename
    @filename = filename
    if File.exists?(@filename)
      puts "WARNING: #{@filename} exists. moving to #{@filename}.old"
      File.rename(@filename, @filename + ".old")
    end
    @script_file = File.open(@filename, 'w')
  end

  def write line
    @script_file << line << "\n"
  end

  def close
    @script_file.close
    system("chmod +x #{@filename}")
  end
end

def self.write_admin_script flowcell_id
  flowcell_id = flowcell_id.upcase

  flowcell = Illuminati::FlowcellData.new flowcell_id
  puts flowcell.base_dir

  script = ScriptWritter.new flowcell.script_path

  script.write "#!/bin/bash"
  script.write "# #{flowcell_id}"
  script.write ""

  command = "cd #{flowcell.base_dir}"
  script.write command
  script.write ""

  command = "#{SCRIPT_PATH}/ngsquery.pl fc_lane_library_samples #{flowcell_id}"
  script.write command

  results = %x[#{command}]
  results.split("\n").each {|line| script.write "# #{line}" }

  script.write ""

  command = "#{CONFIG_SCRIPT} #{flowcell_id}"
  results = %x[#{command}]

  # add the output file to the command as we want it
  # to generate the file when we run this script for reals
  command = command + " config.txt SampleSheet.csv"
  script.write command

  results.split("\n").each {|line| script.write "# #{line}"}
  script.write ""

  command = "cp SampleSheet.csv #{flowcell.base_calls_dir}"
  script.write command

  command = "cd #{flowcell.base_calls_dir}"
  script.write command

  command = "#{File.join(SCRIPT_PATH, "emailer.rb")} \"starting #{flowcell_id}\""
  script.write command
  script.write ""

  command = "#{File.join(SCRIPT_PATH, "logger.rb")} #{flowcell_id} \"starting #{flowcell_id}\""
  script.write command
  script.write ""

  command = "#{CASAVA_PATH}/configureBclToFastq.pl --mismatches 1 --input-dir #{flowcell.base_calls_dir} --output-dir #{flowcell.unaligned_dir}  --flowcell-id #{flowcell.flowcell_id}"
  script.write command
  script.write ""

  command = "cd #{flowcell.unaligned_dir}"
  script.write command
  script.write ""

  align_command = "#{ALIGN_SCRIPT} #{flowcell.flowcell_id} > run_align.out 2>&1"
  command = "nohup make -j 4 POST_RUN_COMMAND=\"#{align_command}\" > make.unaligned.out 2>&1 &"
  script.write command
  script.write ""

  script.write "# after complete, run this command and paste results to wiki page"
  script.write "# fc_info #{flowcell_id}"

  script.close
end
end

if __FILE__ == $0
  Illuminati::write_admin_script flowcell_id
end
