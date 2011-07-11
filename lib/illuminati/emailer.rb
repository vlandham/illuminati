#! /usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))

class Emailer

  EMAIL_LIST = ["jfv@stowers.org"]

  def self.email title, file = nil
    EMAIL_LIST.each do |address|
      command = "mail -s \"#{title}\" #{address}"
      if file
        command += " < #{file}"
      else
        command = "echo \"that is all\" | #{command}"
      end
      system(command)

    end
  end
end

if __FILE__ == $0
  title = ARGV[0]
  file = ARGV[1]
  if title
    Emailer.email title, file
  else
    puts "ERROR: call with title of email"
  end
end
