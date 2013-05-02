#! /usr/bin/env ruby

require 'optparse'

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
POSTRUN_SCRIPT = File.join(BASE_BIN_DIR, "post_run")

require 'illuminati'


ALIGN_SCRIPT = "eland_plain.sh"
ALIGN_SCRIPT_ORIGIN = File.join(Illuminati::ASSESTS_PATH, ALIGN_SCRIPT)

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
      puts result
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
    def run(flowcell_id, options)
      output "starting alignment step for #{flowcell_id}"
      if !options[:fake]
        Emailer.email "starting align step for #{flowcell_id}" unless @test
      end
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
        config_file = ""
        if options[:config] 
          config_file = options[:config]
        else
          config_file = File.join(flowcell.base_dir, "config.txt")
        end

        if File.exists? config_file
          if options[:force] and File.exists?(flowcell.aligned_dir)
            command = "rm -rf #{flowcell.aligned_dir}"
            puts "---- WARNING ----"
            puts "REMOVING ALIGNMENT DIRECTORY: "
            puts "#{flowcell.aligned_dir}"
            execute command
          end
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


          command = "export PATH=#{CASAVA_PATH}:$PATH"
          execute command
          execute("echo $PATH")

          local_align_script_path = File.join(flowcell.unaligned_dir, ALIGN_SCRIPT)
          command = "cp #{ALIGN_SCRIPT_ORIGIN} #{local_align_script_path}"
          execute command

          post_command = "#{POSTRUN_SCRIPT} #{flowcell.flowcell_id} > post_run.out 2>&1"
          command = "cd #{flowcell.aligned_dir};"
          # command += " qsub -cwd -v PATH -pe make #{NUM_PROCESSES} #{local_align_script_path} \\"#{post_command}\\""
          # command += " qsub -cwd -v PATH -pe make #{NUM_PROCESSES/2} #{local_align_script_path}"
          # command += " nohup make -j 8 POST_RUN_COMMAND=\\"#{post_command}\\" all > make.aligned.out 2>&1  &"
          # command += " qsub -cwd -v PATH #{local_align_script_path} \\"#{post_command}\\""
          command += " qsub -cwd -v PATH #{local_align_script_path}"
          if options[:postrun]
            command += " \"#{post_command}\""
          else
            puts "NOT PERFORMING POSTRUN"
          end
          if !options[:fake]
            execute command
          end

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

  options = {}
  options[:postrun] = true
  options[:fake] = false
  options[:force] = false
  options[:config] = nil

  opts = OptionParser.new do |o|
    o.banner = "Usage: align_runner.rb [Flowcell Id] [options]"
    # o.on('-t', '--test', 'do not write out to disk') {|b| options[:test] = b}
    o.on('--no-postrun', 'No post run. only alignment') {|b| options[:postrun] = false}
    o.on('--fake', 'Do not execute last step') {|b| options[:fake] = true}
    o.on('--force', 'Overwrite Aligned Directory') {|b| options[:force] = true}
    o.on('--config CONFIG_FILE', 'manually specify config.txt file') {|b| options[:config] = File.expand_path(b)}

    o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
    o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
  end

  opts.parse!

  if flowcell_id
    puts "Flowcell ID: #{flowcell_id}"
  else
    puts "ERROR: call with flowcell id"
    puts "       align_runner.rb [FLOWCELL_ID]"
    exit
  end

  runner = Illuminati::AlignRunner.new
  runner.run(flowcell_id, options)
end
