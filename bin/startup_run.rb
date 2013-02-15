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

require 'optparse'
require 'illuminati'


module Illuminati
  # Illuminati executables, so they don't need to be modifiable.
  BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))
  ALIGN_SCRIPT = File.join(BASE_BIN_DIR, "align_runner.rb")
  CONFIG_SCRIPT = File.join(BASE_BIN_DIR, "config_maker.rb")
  LOGGER_SCRIPT = File.join(BASE_BIN_DIR, "logger.rb")
  EMAILER_SCRIPT = File.join(BASE_BIN_DIR, "emailer.rb")

  BCL2FASTQ_SCRIPT = "bcl2fastq_plain.sh"
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
    def self.write_admin_script flowcell_id, options = {}
      @options = options
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

      command = "#{CONFIG_SCRIPT} --lanes #{@options[:lanes]} #{flowcell_id}"
      results = %x[#{command}]

      # add the output file to the command as we want it
      # to generate the file when we run this script for reals
      if @options[:create_sample_sheet]
        command += " -s #{@options[:sample_sheet]}"
      end

      if @options[:create_config]
        command += " -c config.txt"
      end

      script.write command

      results.split("\n").each {|line| script.write "# #{line}"}
      script.write ""

      command = "cp #{@options[:sample_sheet]} #{flowcell.base_calls_dir}"
      script.write command

      command = "cd #{flowcell.base_calls_dir}"
      script.write command

      command = "#{EMAILER_SCRIPT} \"starting #{flowcell_id}\""
      script.write command
      script.write ""

      command = "#{LOGGER_SCRIPT} #{flowcell_id} \"starting #{flowcell_id}\""
      script.write command
      script.write ""

      command = "#{CASAVA_PATH}/configureBclToFastq.pl --ignore-missing-stats --mismatches 1 --input-dir #{flowcell.base_calls_dir} --output-dir #{flowcell.unaligned_dir}  --flowcell-id #{flowcell.flowcell_id}"

      if @options[:type] == :dual
        command += " --use-bases-mask Y*,I*,I*,Y*"
      end

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

      command = "qsub -cwd -v PATH #{local_bcl2fastq_script_path}"

      if @options[:align]
        align_options = @options[:postrun] ? "" : "--no-postrun"
        align_command = "#{ALIGN_SCRIPT} #{flowcell.flowcell_id} #{align_options} > run_align.out 2>&1"
        command += "  \"#{align_command}\""
      end

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
  options = {}
  options[:lanes] = [1,2,3,4,5,6,7,8]
  options[:type] = :single
  options[:align] = true
  options[:postrun] = true
  options[:create_sample_sheet] = true
  options[:create_config] = true
  options[:sample_sheet] = "SampleSheet.csv"

  opts = OptionParser.new do |o|
    o.banner = "Usage: startup_run.rb [Flowcell Id] [options]"
    o.on('-d', '--dual', 'Flowcell is dual indexed') {|b| options[:type] = :dual}
    o.on( '--no-align', 'Disable the align step') {|b| options[:align] = false}
    o.on( '--no-postrun', 'Disable the align step') {|b| options[:postrun] = false}
    o.on( '--no-sample_sheet', 'Disable the samplesheet step') {|b| options[:create_sample_sheet] = false}
    o.on( '--no-config', 'Disable the config step') {|b| options[:create_config] = false}
    o.on("--lanes 1,2,3,4,5,6,7,8" , Array, 'Specify which lanes should be run') {|b| options[:lanes] = b}
    o.on('--sample_sheet SampleSheet.csv', String, 'Specify local samplesheet.csv name') {|b| options[:sample_sheet] = b}
    o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
    o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
  end

  opts.parse!
  options[:lanes] = options[:lanes].join(",")

  puts options.inspect

  if flowcell_id
    puts "Flowcell ID: #{flowcell_id}"
  else
    puts "ERROR: no flow cell ID provided"
    exit
  end
  Illuminati::Starter::write_admin_script flowcell_id, options
end
