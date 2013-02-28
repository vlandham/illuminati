#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

input_json_filename = ARGV[0]

if !input_json_filename or !File.exist?(input_json_filename)
  puts "Usage:"
  puts "\tlims_upload_samples.rb [lims_data.json]"
  exit(1)
end

api_token = '70e0222a684f3734a01c0e563c4f542c'

root_url = 'http://limskc01/zanmodules'


url = URI.parse("#{root_url}/molbio/api/ngs/flowcells/setDataForSamples")
req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' => 'application/json'})
req.basic_auth 'apitoken', api_token

json_data = JSON.parse(File.open(input_json_filename,'r').read)

json_data.each do |sample_data|
  next unless sample_data['sampleYield'] != nil
  params = {'samplesData' => [sample_data]}
  req.body = params.to_json

  resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
  puts resp.body
end


