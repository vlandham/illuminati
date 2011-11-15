#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

OUTSOURCE_TEST = false

require 'post_runner'
require 'illuminati'

module Illuminati
  class OutsourcePaths < Paths
    OUTSOURCE_BASE = File.join("/qcdata", "Outsource")
    TUFTS_BASE = File.join(OUTSOURCE_BASE, "genomics.med.tufts.edu")
    def self.base
      TUFTS_BASE
    end
  end
end

if __FILE__ == $0
  flowcell_id = ARGV[0]
  options = {}
  opts = OptionParser.new do |o|
    o.banner = "Usage: post_runner.rb [Flowcell Id] [options]"
    o.on('-t', '--test', 'do not write out to disk') {|b| options[:test] = b}
    o.on('-s', "--steps step1,step2,step3" , Array, 'Specify only which steps of the pipeline should be executed') {|b| options[:steps] = b.collect {|step| step} }
    o.on('-y', '--yaml YAML_FILE', String, "Yaml configuration file that can be used to load options.","Command line options will trump yaml options") {|b| options.merge!(Hash[YAML::load(open(b)).map {|k,v| [k.to_sym, v]}]) }
    o.on('-h', '--help', 'Displays help screen, then exits') {puts o; exit}
  end

  opts.parse!

  if flowcell_id
    paths = Illuminati::FlowcellPaths.new flowcell_id, OUTSOURCE_TEST, Illuminati::OutsourcePaths
    flowcell = Illuminati::FlowcellRecord.find flowcell_id, paths
    runner = Illuminati::PostRunner.new flowcell, options
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
