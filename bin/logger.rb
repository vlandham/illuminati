#! /usr/bin/env ruby

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
