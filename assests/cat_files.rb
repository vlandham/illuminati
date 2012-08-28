
require 'json'

database_filename = ARGV[0]
database_index = ENV["SGE_TASK_ID"].to_i - 1

puts "database file:#{database_filename}"
puts "index: #{database_index}"

database = JSON.parse(File.open(database_filename, 'r').read)

entry = database[database_index]

command = "cat #{entry["files"].chomp} > #{entry["destination"]}"
puts command
`#{command}`


