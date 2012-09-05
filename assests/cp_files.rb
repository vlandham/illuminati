
require 'json'

database_filename = ARGV[0]
database_index = ENV["SGE_TASK_ID"].to_i - 1

database = JSON.parse(File.open(database_filename, 'r').read)

entry = database[database_index]

command = "mkdir -p #{File.dirname(entry["output"])}"
puts command
`#{command}`

flag = entry["recursive"] ? "-r" : ""

command = "cp #{flag} #{entry["input"]} #{entry["output"]}"
puts command
`#{command}`


