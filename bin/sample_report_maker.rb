#! /usr/bin/env ruby

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'
require 'illuminati/constants'
require 'sample_report_maker'


if __FILE__ == $0
  flowcell_id = ARGV[0]
  output_path = ARGV[1]
  if !output_path
    base_path = Dir.glob(File.join(Illuminati::Paths.base, "*#{flowcell_id}"))[0]
    if !base_path
      puts "ERROR: cannot find base path. please specify"
      exit(1)
    end
    output_path = File.join(base_path, "Sample_Report.csv")
  end

  paths = Illuminati::FlowcellPaths.new flowcell_id
  flowcell = Illuminati::FlowcellRecord.find flowcell_id, paths
  sample_report = Illuminati::SampleReportMaker.make(flowcell)
  File.open(output_path, 'w') do |file|
    file.puts sample_report
  end

end
