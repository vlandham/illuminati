#! /usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'illuminati'

class ConfigFileMaker

  def self.make data, flowcell, output_file
    cf = ConfigFileMaker.new(data, flowcell)
    cf.output(output_file)
  end

  def initialize data, flowcell
    @rows = data
    @input_dir = flowcell.unaligned_dir
    @flowcell_id = flowcell.flowcell_id
  end

  def output output_file
    template = ERB.new File.new("#{SCRIPT_PATH}/config_template_1_8.erb").read, nil, "%<>"
    output = template.result(binding)

    puts "config file"

    if output_file
      puts "outputing config file to #{output_file}"
      File.open(output_file, 'w') do |file|
        file << output
      end
    else
      puts output
    end
  end
end #ConfigFile

