#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
POSTRUN_SCRIPT = File.join(BASE_BIN_DIR, "post_run")

require 'illuminati'


ALIGN_SCRIPT = "eland.sh"
ALIGN_SCRIPT_ORIGIN = File.join(ASSESTS_PATH, ALIGN_SCRIPT)

module Illuminati
  #
  # Class to manage the execution of the alignment
  # portion of the CASAVA 1.8 pipeline.
  #
  # All this needs to do is run the configure script
  # and then run make inside the Aligned directory.
  #
  # The config.txt file used for alignment should have
  # already been created during the startup process, to allow
  # for visual inspection.
  #
  # If it fails, AlignRunner should email using Emailer.
  #
  class AlignRunner
    attr_accessor :test

    def initialize
      @test = false
      output_filename = "run_align_step.out"
      @output_file = File.new(output_filename, 'w')
    end

    def finish
      output "Done"
      @output_file.close
    end

    def output message
      @output_file << message << "\n"
      puts message
    end

    def execute command
      output command
      result = %x[#{command}] unless @test
      result
    end

    def valid_status status_string
      status_lines = status_string.split("\n")
      status_lines.each {|line| output "# #{line}\n"}
      status_lines.each do |line|
        if line =~ /ERROR/
          puts "Error in status"
          return false
        end
      end
      true
    end

    #
    # Main entry point for AlignRunner.
    #
    def run(flowcell_id)
      output "starting alignment step for #{flowcell_id}"
      Emailer.email "starting align step for #{flowcell_id}" unless @test
      SolexaLogger::log flowcell_id, "starting alignment", @test

      flowcell = nil

      begin
        flowcell = FlowcellPaths.new(flowcell_id)
      rescue Exception => err
        output "Problem creating flowcell"
        output "Flowcell id: #{flowcell_id}."
        Emailer.email "Error flowcell in aligner for #{flowcell_id}" unless @test
        output err
      end

      if flowcell
        config_file = File.join(flowcell.base_dir, "config.txt")
        if File.exists? config_file
          command = "#{CASAVA_PATH}/configureAlignment.pl #{config_file} 2>&1"
          status = execute command

          if !valid_status(status)
            output "Problem with config file. Exiting"
            Emailer.email "Error config.txt file is invalid for #{flowcell_id}" unless @test
            raise "invalid config file"
          else
            output "Config test passed"
          end

          command += " --make"
          execute command

          command = "cp #{ALIGN_SCRIPT_ORIGIN} #{flowcell.aligned_dir}"
          execute command

          post_command = "#{POSTRUN_SCRIPT} #{flowcell.flowcell_id} > post_run.out 2>&1"
          command = "cd #{flowcell.aligned_dir};"
          command += " qsub -cwd -v PATH -pe make #{NUM_PROCESSES} #{ALIGN_SCRIPT} \"#{post_command}\""
          # command += " nohup make -j 8 POST_RUN_COMMAND=\\"#{post_command}\\" all > make.aligned.out 2>&1  &"
          execute command

        else
          output "ERROR: no config.txt file found in #{flowcell.base_dir}"
        end
      end

      finish
    end
  end
end

if __FILE__ == $0
  flowcell_id = ARGV[0]

  if flowcell_id
    puts "Flowcell ID: #{flowcell_id}"
  else
    puts "ERROR: call with flowcell id"
    puts "       align_runner.rb [FLOWCELL_ID]"
    exit
  end

  runner = Illuminati::AlignRunner.new
  runner.run(flowcell_id)
end
