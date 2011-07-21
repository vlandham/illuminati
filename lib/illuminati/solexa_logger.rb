require 'json'
require 'fileutils'

require 'illuminati/constants'

module Illuminati
  #
  # Quick and terrible logging helper class.
  # Logging mostly means that a message string and
  # date/time are captured in a log file for later use.
  # This could serve as a mechanism by which Illuminati communicates
  # to other applications (but not a very good mechanism).
  # Currently, logs are stored in json format.
  #
  class SolexaLogger
    #
    # Log a message to a log file specific to a particular flowcell
    #
    # == Parameters
    # flowcell_id::
    #   id of the flowcell to log. Used to determine what file to
    #   write to.
    #
    # status::
    #   Actual message to be logged.
    #
    # test::
    #   If true, logging will be done in a separate 'test' file.
    #
    def self.log flowcell_id, status, test = false
      if !test and !File.exists?(LOGS_PATH)
        puts "creating dir: #{LOGS_PATH}"
        FileUtils.mkdir_p LOGS_PATH
      end
      log_filename = File.join(LOGS_PATH, "#{flowcell_id}.log")
      if test
        log_filename = log_filename + ".test"
      end
      time = Time.now
      File.open(log_filename, 'a') do |file|
        data = {:time => time, :message => status}
        file << data.to_json << "\n"
      end
    end

  end
end

