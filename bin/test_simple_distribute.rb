#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'simple_distribute/simple_distribute'

distributer = SimpleDistribute::Distributer.new(Dir.pwd)

task_file = File.join(File.dirname(__FILE__), "..", "assests", "email.rb")

distributer.submit(task_file, {:prefix => "test", :args => "123 task"})
