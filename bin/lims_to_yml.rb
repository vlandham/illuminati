#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'optparse'
require 'illuminati'
require 'yaml'

flowcell_id = ARGV[0]


external_data = Illuminati::ExternalDataLimsNew.new

samples = external_data.sample_data_for(flowcell_id)
distributions = external_data.distributions_for(flowcell_id)

data = {}
data[:samples] = samples
data[:distributions] = distributions

outputfilename = "#{flowcell_id}.yaml"

File.open(outputfilename, 'w') do |file|
  file.puts data.to_yaml
end
