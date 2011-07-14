require 'illuminati/constants'

module Illuminati
  class Emailer

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
end

