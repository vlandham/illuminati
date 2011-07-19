#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))

require 'post_runner'

BARCODE_TEST = true

module Illuminati
  class BarcodeRunner < PostRunner
    def initialize flowcell, test = false
      super flowcell, test
    end

    def run
      start_flowcell
      distributions = DistributionData.distributions_for @flowcell.id

      fastq_groups = group_fastq_files(@flowcell.unaligned_project_dir,
                                       @flowcell.fastq_combine_dir,
                                       @flowcell.fastq_filter_dir)
      split_custom_barcodes fastq_groups

      stop_flowcell
    end
  end
end


if __FILE__ == $0
  flowcell_id = ARGV[0]
  if flowcell_id
    flowcell = Illuminati::FlowcellData.new flowcell_id, BARCODE_TEST
    runner = Illuminati::BarcodeRunner.new flowcell, BARCODE_TEST
    runner.run
  else
    puts "ERROR: call with flowcell id"
    puts "       post_runner.rb [FLOWCELL_ID]"
  end
end
