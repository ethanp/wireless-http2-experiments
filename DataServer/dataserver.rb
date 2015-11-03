require 'rubygems'
require 'sinatra'
require 'json'

get '/' do
  "You've reached the DataServer. What may I log today?"
end

post '/data' do
  puts params
  request.body.rewind
  # req_bod = JSON.parse request.body.read
  raw_bod = request.body.read
  formattedNow = Time.now.strftime "%m:%d:%T:%3N"
  logline = "{\"time\":\"#{formattedNow}\",\"data\":#{raw_bod}}"
  open('data.txt', 'a') { |f| f.puts logline }
  logline
end
