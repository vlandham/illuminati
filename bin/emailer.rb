#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'illuminati'

if __FILE__ == $0
  title = ARGV[0]
  file = ARGV[1]
  if title
    Illuminati::Emailer.email title, file
  else
    puts "ERROR: call with title of email"
  end
end
