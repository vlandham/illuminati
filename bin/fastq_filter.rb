#!/usr/bin/env ruby

line_count = 0
printing = false
ARGF.each do |line|
  if line_count == 0
    match = line =~ /^@.*\d+:([NY]):\d+:.*$/
    if !match
      puts "ERROR: problem with input\n#{line}"
      raise 'invalid input'
    end
    printing = ($1 == "N") ? true : false
  end
  puts line if printing
  line_count = (line_count + 1) % 4
end

