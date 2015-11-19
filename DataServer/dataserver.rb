require 'rubygems'
require 'sinatra'
require 'json'

set :bind, '192.168.0.17'

get '/' do
 "You've reached the DataServer. What may I log today?"
end

post '/data' do
  request.body.rewind
  data = request.body.read
  # data_dict = JSON.parse data
  time = Time.now.strftime "%m:%d:%T:%3N"
  logline = "{\"time\":\"#{time}\",\"data\":#{data}}"
  prefix = Time.now.strftime "%m-%d-%H"
  open("#{prefix}_data.txt", 'a') { |f| f.puts logline }
  logline
end
