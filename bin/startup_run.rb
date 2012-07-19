#! /usr/bin/env ruby

#
# startup is the first script to run to begin the primary analysis pipeline.
# provide it with a flowcell id and it takes care of the rest!
#
# It will create a run script (currently in /solexa/run/) with the name
# [flowcell_id].sh, which contains all the code to start the pipeline.
#
# It is kept as a separate file to provide a record of what operations occured
# during the pipeline. This is also in keeping with how the process functioned
# previously, and provides some guidance for future runs if Illuminati breaks down.
#
# And its a final stopping point to check the output generated in the run script to
# ensure that everything looks half-way decent.
#

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'


module Illuminati
  # Illuminati executables, so they don't need to be modifiable.
  BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
  ALIGN_SCRIPT = File.join(BASE_BIN_DIR, "align_runner.rb")
  CONFIG_SCRIPT = File.join(BASE_BIN_DIR, "config_maker.rb")
  LOGGER_SCRIPT = File.join(BASE_BIN_DIR, "logger.rb")
  EMAILER_SCRIPT = File.join(BASE_BIN_DIR, "emailer.rb")

  BCL2FASTQ_SCRIPT = "bcl2fastq.sh"
  BCL2FASTQ_SCRIPT_ORIGIN = File.join(ASSESTS_PATH, BCL2FASTQ_SCRIPT)

  #
  # Helper class to write out script commands to run script.
  #
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

  #
  # Creates the output for the run script and outputs
  # it to the run script.
  #
  class Starter
    def self.write_admin_script flowcell_id
      flowcell_id = flowcell_id.upcase

      flowcell = FlowcellPaths.new flowcell_id
      puts flowcell.base_dir

      script = ScriptWritter.new flowcell.script_path

      script.write "#!/bin/bash"
      script.write "# #{flowcell_id}"
      script.write ""

      command = "cd #{flowcell.base_dir}"
      script.write command
        script.write ""

      command = "#{ScriptPaths::lims_info} #{flowcell_id}"
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

      command = "#{EMAILER_SCRIPT} \"starting #{flowcell_id}\""
      script.write command
      script.write ""

      command = "#{LOGGER_SCRIPT} #{flowcell_id} \"starting #{flowcell_id}\""
      script.write command
      script.write ""

      command = "#{CASAVA_PATH}/configureBclToFastq.pl --mismatches 1 --input-dir #{flowcell.base_calls_dir} --output-dir #{flowcell.unaligned_dir}  --flowcell-id #{flowcell.flowcell_id}"
      script.write command
      script.write ""

      command = "cd #{flowcell.unaligned_dir}"
      script.write command
      script.write ""

      # ensure casava bin path is in $PATH
      command = "export PATH=#{CASAVA_PATH}:$PATH"
      script.write command
      script.write ""

      command = "cp #{File.expand_path(BCL2FASTQ_SCRIPT_ORIGIN)} ./"
      script.write command
      script.write ""

      local_bcl2fastq_script_path = File.join(flowcell.unaligned_dir, BCL2FASTQ_SCRIPT)

      align_command = "#{ALIGN_SCRIPT} #{flowcell.flowcell_id} > run_align.out 2>&1"
      # command = "nohup make -j 4 POST_RUN_COMMAND=\\"#{align_command}\\" > make.unaligned.out 2>&1 &"
      # command = "qsub -cwd -v PATH -pe make #{NUM_PROCESSES} #{local_bcl2fastq_script_path} \\"#{align_command}\\""
      command = "qsub -cwd -v PATH -pe make #{NUM_PROCESSES} #{local_bcl2fastq_script_path}"
      # command = "qsub -cwd -v PATH #{local_bcl2fastq_script_path} \\"#{align_command}\\""
      script.write command
      script.write ""

      script.write "# after complete, run this command and paste results to wiki page"
      script.write "# fc_info #{flowcell_id}"

      script.close
    end
  end
end

if __FILE__ == $0
  flowcell_id = ARGV[0]

  if flowcell_id
    puts "Flowcell ID: #{flowcell_id}"
  else
    puts "ERROR: no flow cell ID provided"
    exit
  end
  Illuminati::Starter::write_admin_script flowcell_id
end
