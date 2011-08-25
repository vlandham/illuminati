#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'
require 'post_runner'

SAMPLE_SHEET_TEST = true

module Illuminati
  class SampleSheetRunner < PostRunner
    def initialize flowcell, test = false
      super flowcell, test
    end

    def run
      start_flowcell
      distributions = DistributionData.distributions_for @flowcell.paths.id

      create_sample_report
      distribute_sample_report distributions

      create_custom_stats_files
      distribute_custom_stats_files distributions

      distribute_to_qcdata
      stop_flowcell
    end
  end
end


if __FILE__ == $0
  flowcell_id = ARGV[0]
  if flowcell_id
    paths = Illuminati::FlowcellPaths.new flowcell_id, SAMPLE_SHEET_TEST
    flowcell = Illuminati::FlowcellRecord.find flowcell_id, paths
    runner = Illuminati::SampleSheetRunner.new flowcell, SAMPLE_SHEET_TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
