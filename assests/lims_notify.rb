
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

TEST = false
# only works with default flowcell paths
flowcell_id = ARGV[0]

paths = Illuminati::Paths
fc_paths = Illuminati::FlowcellPaths.new flowcell_id, TEST, paths
flowcell = Illuminati::FlowcellRecord.find flowcell_id, fc_paths
notifier = Illuminati::LimsNotifier.new(flowcell)
notifier.upload_to_lims
notifier.complete_analysis
