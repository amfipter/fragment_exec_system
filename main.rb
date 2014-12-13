#!/usr/bin/env ruby
require './connect.rb'

$broadcast = true
$out_port = 30000
$left_client = nil
$right_client = nil
$mutex = Mutex.new

if(ARGV[0].eql? '0')
	puts '0'
	Connection::broadcast()
	Connection::create_connection()
elsif(ARGV[0].eql? '1')
	puts '1'
	Connection::connect()
	Connection::broadcast()
	Connection::create_connection()
elsif(ARGV[0].eql? '2')
	Connection::connect()
else
	puts "wrong arguments. :("
	exit
end

Thread.list.each { |thr| thr.join if thr != Thread.main}
#connection established

unless($left_client.nil?)
	Connection::left_listener()
end

unless($right_client.nil?)
	Connection::right_listener()
end

Thread.list.each { |thr| thr.join if thr != Thread.main}