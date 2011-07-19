#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))

require 'post_runner'

module Illuminati
  class QcdataRunner < PostRunner
    def initialize flowcell, test = false
      super flowcell, test
    end

    def run
      start_flowcell
      distribute_to_qcdata
      stop_flowcell
    end
  end
end


if __FILE__ == $0
  flowcell_id = ARGV[0]
  if flowcell_id
    flowcell = Illuminati::FlowcellData.new flowcell_id, TEST
    runner = Illuminati::QcdataRunner.new flowcell, TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
