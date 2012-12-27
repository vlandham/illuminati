
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

TEST = false
# only works with default flowcell paths
flowcell_id = ARGV[0]
wait_time = ARGV[1]

if wait_time
  wait_time = wait_time.to_i
else
  wait_time = 0
end

if wait_time and wait_time > 0
  sleep(wait_time.minutes)
end

paths = Illuminati::Paths
fc_paths = Illuminati::FlowcellPaths.new flowcell_id, TEST, paths
flowcell = Illuminati::FlowcellRecord.find flowcell_id, fc_paths
notifier = Illuminati::LimsNotifier.new(flowcell)
notifier.complete_analysis
