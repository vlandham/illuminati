#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))

require 'post_runner'
QCDATA_TEST = FALSE

module Illuminati
  class QcdataRunner < PostRunner
    def initialize flowcell, test = false
      super flowcell, test
    end

    def run
      start_flowcell
      distributions = DistributionData.distributions_for @flowcell.id
      distribute_aligned_stats_files distributions
      stop_flowcell
    end
  end
end


if __FILE__ == $0
  flowcell_id = ARGV[0]
  if flowcell_id
    flowcell = Illuminati::FlowcellData.new flowcell_id, QCDATA_TEST
    runner = Illuminati::QcdataRunner.new flowcell, QCDATA_TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
