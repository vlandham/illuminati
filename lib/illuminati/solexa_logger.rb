#! /usr/bin/env ruby
require 'json'

$: << File.expand_path(File.dirname(__FILE__))

class SolexaLogger

  LOG_DIR = File.expand_path(File.join("/qcdata", "log"))

  def self.log flowcell_id, status, test = false
    log_filename = File.join(LOG_DIR, "#{flowcell_id}.log")
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


if __FILE__ == $0
  flowcell_id = ARGV[0]
  message = ARGV[1]
  if flowcell_id
    SolexaLogger.log flowcell_id, message
  else
    puts "ERROR: call with flowcell_id and message"
  end
end
