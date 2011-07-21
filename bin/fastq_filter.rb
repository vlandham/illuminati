#!/usr/bin/env ruby

#
# Script used by the filter process of post run to
# remove those reads that do not pass filter.
# Fastq contents are piped in, and output is redirected
# to file.
#
# Slower than grep. But provides complete control.
# CASAVA 1.8 documentation had an example of how to do
# this filtering, but there were a number of bugs in the
# code. So we just wrote our own.
#
# Feel free to replace with a faster version in your language
# of choice if you want.
#
# Execution example:
# $ zcat s_1_1_NoIndex.fastq.gz | fastq_filter.rb | gzip -c > filter/s_1_1_NoIndex.fastq.gz
#

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

