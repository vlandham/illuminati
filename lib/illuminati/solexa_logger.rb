require 'json'
require 'fileutils'

require 'illuminati/constants'

module Illuminati
  class SolexaLogger
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
        #file << date << "," << "\"#{status}\"" << "\n"
      end
    end

  end
end

