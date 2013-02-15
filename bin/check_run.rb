#! /usr/bin/env ruby

require 'digest/md5'

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
BASE_BIN_DIR = File.expand_path(File.dirname(__FILE__))

@@log = ""

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def cyan(text); colorize(text, 36); end

def notify message
  puts message
  @@log << message + "\n"
end

def email title, message
  emailer = File.join(BASE_BIN_DIR, "emailer.rb")
  message_filename = File.join("/tmp","illuminati_message.txt")
  File.open(message_filename,'w') do |file|
    file.puts message
  end
  Illuminati::Emailer.email title, message_filename
end

require 'optparse'
require 'illuminati'

def test_exist_dir dir
  present = true
  present = File.exists?(dir) and File.directory?(dir)
  if !present
    notify "ERROR: no #{File.basename(dir)} directory found"
    notify " should be at:"
    notify " #{dir}"
    notify ""
  else
    notify "OK: #{File.basename(dir)} found"
  end
  present
end

def test_exist file
  present = true
  present = File.exists?(file)
  if !present
    notify "ERROR: no #{File.basename(file)} directory found"
    notify " should be at:"
    notify " #{file}"
    notify ""
  else
    puts "OK: #{File.basename(file)} found"
    puts " in #{File.dirname(file)}"
  end
  present
end

def hash_file filename
  md5 = ""
  if File.exists?(filename)
    md5 = Digest::MD5.file(filename).hexdigest
  end
  md5
end

module Illuminati
  class RunCheck
    attr_accessor :flowcell_id, :lims_data
    def initialize flowcell_id, options = {}
      self.flowcell_id = flowcell_id
    end

    def run
      self.lims_data = get_lims_data(self.flowcell_id)
      puts @lims_data.inspect
      projects = aggregate_project_dirs(self.lims_data)
      puts projects.inspect
      check_fastqcs(projects)
      check_sample_report(projects)
      check_fastq_files(projects)
    end

    def check_fastq_files(projects)
    end

    def check_sample_report(projects)
      hashes = []
      projects.each do |project|
        sample_report_filename = File.join(project["path"], "Sample_Report.csv")
        if test_exist sample_report_filename
          hash = hash_file(sample_report_filename)
          if !hashes.empty? and !hashes.include?(hash)
            notify("WARNING: Sample_Report.csv does not match")
            notify(" in #{project["path"]}")
          end
          hashes << hash
        end
      end
    end

    def check_fastqcs(projects)
      hashes = []
      projects.each do |project|
        hash = check_for_fastqc(project)
        if !hashes.empty? and !hashes.include?(hash)
          notify("WARNING: Fastqc output does not match")
          notify(" in #{project["path"]}")
        end
        hashes << hash
      end
    end

    def check_for_fastqc(project)
      fastqc_path = File.join(project["path"], "fastqc")
      hash = ""
      if test_exist_dir(fastqc_path)
        fastqc_plots_filename = File.join(fastqc_path, "fastqc_plots.html")
        if test_exist(fastqc_plots_filename)
          hash = hash_file(fastqc_plots_filename)
        end
      end
      hash
    end

    def aggregate_project_dirs lims_data
      projects = {}
      lims_data["samples"].each do |lims_sample|
        id = lims_sample["orderID"]
        if !projects[id]
          project = {}
          project["path"] = lims_sample["resultsPath"]
          project["samples"] = []
          projects[id] = project
        end
        sample = {"name" => lims_sample["sampleName"], "index" => lims_sample["index"],
        "index_type" => lims_sample["indexesUsed"], "read_type" => lims_sample["readType"]}
        projects[id]["samples"] << sample
      end
      projects.values
    end

    def get_lims_data flowcell_id
      notify "Contacting LIMS."
      lims = ExternalDataLims.new
      data = lims.data_for(flowcell_id)
      if data["samples"] and data["samples"].length > 0
        notify "#{data["samples"].length} samples found for flowcell #{flowcell_id}"
      else
        notify "ERROR: no samples found for flowcell id '#{flowcell_id}'"
        notify " is this a valid flowcell?"
        notify " is this flowcell in LIMS?"
      end
      data
    end
  end
  class HiSeqRunCheck < RunCheck
    def initialize flowcell_id, options = {}
      super(flowcell_id, options)
    end

    def run
      super()
    end
  end
end


if __FILE__ == $0

  id = ARGV[0]
  options = {}
  opts = OptionParser.new do |o|
    o.banner = "Usage: check_flowcell path/to/flowcell/dir"
    # o.on('--id flowcell id', String, 'Manually specify the flowcell ID') {|b| options[:id] = b}
    # o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
    o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
  end

  opts.parse!

  # puts options.inspect

  if id
    checker = Illuminati::HiSeqRunCheck.new id, options
    checker.run
    # email("check run for #{id}", @@log)
  else
    puts "ERROR: call with id of flowcell"
    puts "       check_run [flowcell_id]"
  end
end
