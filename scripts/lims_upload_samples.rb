#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

api_token = '70e0222a684f3734a01c0e563c4f542c'

root_url = 'http://limskc01/zanmodules'


url = URI.parse("#{root_url}/molbio/api/ngs/flowcells/setDataForSamples")
req = Net::HTTP::Post.new(url.path, initheader = {'Content-Type' => 'application/json'})
req.basic_auth 'apitoken', api_token

params = {'fcIdent' => 'C01VYACXX'}

req.body = params.to_json

resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
puts resp.body
