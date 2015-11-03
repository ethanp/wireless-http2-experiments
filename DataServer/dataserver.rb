require 'rubygems'
require 'sinatra'
require 'json'

get '/' do
  "You've reached the DataServer; what may I log today?"
end

outfile =

post '/data' do
  request.body.rewind
  # data = JSON.parse request.body.read
  data = params['data']
  formattedNow = Time.now.strftime("%T%3N")
  logline = "{\"time\":\"#{formattedNow}\",\"data\":#{data}}"
  open('data.txt', 'a') { |f| f.puts logline }
  logline
end
