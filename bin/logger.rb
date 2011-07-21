#! /usr/bin/env ruby

# Quick script to allow for calling the logging system from
# external programs easily.
#
# == Arguments
# ::flowcell_id
#   Flowcell ID of the flowcell we are logging about
#
# ::message
#   Message string to log
#
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

if __FILE__ == $0
  flowcell_id = ARGV[0]
  message = ARGV[1]
  if flowcell_id
    Illuminati::SolexaLogger.log flowcell_id, message
  else
    puts "ERROR: call with flowcell_id and message"
  end
end
