
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'
require 'illuminati/emailer'

step = ARGV[0]
flowcell = ARGV[1]

Illuminati::Emailer.email "#{step} step finished for #{flowcell}"
