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
  if flowcell_id
    paths = Illuminati::FlowcellPaths.new flowcell_id, OUTSOURCE_TEST, Illuminati::OutsourcePaths
    flowcell = Illuminati::FlowcellRecord.find flowcell_id, paths
    runner = Illuminati::PostRunner.new flowcell, OUTSOURCE_TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
