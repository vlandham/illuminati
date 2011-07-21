require 'illuminati/constants'

module Illuminati
  #
  # Helper class to facilitate the emailing of messgages and files.
  #
  class Emailer
    #
    # Email a message and optional file content. Email addresses that will
    # be sent to when this method is called are defined in the EMAIL_LIST
    # array in constants.rb
    #
    # == Parameters:
    # title::
    #   string that will be used as the title of the email
    #
    # file::
    #   optional filename. If not nil, the contents of the file will
    #   be echoed into the body of the email.
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

