#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))

require 'post_runner'
require 'illuminati/sample_report_maker'

TEST_RUNNER_TEST = true

module Illuminati
  class QcdataRunner < PostRunner
    def initialize flowcell, test = false
      super flowcell, test
    end

    def run
      start_flowcell

      distributions = DistributionData.distributions_for @flowcell.id
      run_undetermined_unaligned distributions

      stop_flowcell
    end
  end
end


if __FILE__ == $0
  flowcell_id = ARGV[0]
  if flowcell_id
    flowcell = Illuminati::FlowcellPaths.new flowcell_id, TEST_RUNNER_TEST
    runner = Illuminati::QcdataRunner.new flowcell, TEST_RUNNER_TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end

