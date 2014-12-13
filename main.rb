#!/usr/bin/env ruby
require './connect.rb'
require './execution.rb'
require './data.rb'
require './task.rb'

$broadcast = true
$out_port = 30000
$left_client = nil
$right_client = nil
$mutex = Mutex.new
$node_id = nil
$task_stack = Array.new
$data_stack = Array.new
$debug_trace = false

if(ARGV[0].eql? '0')
	puts '0'
	Connection::broadcast()
	Connection::create_connection()
	Connection::wait_last_connection()
	$node_id = 0
elsif(ARGV[0].eql? '1')
	puts '1'
	Connection::connect()
	Connection::broadcast()
	Connection::create_connection()
	Connection::wait_last_connection()
elsif(ARGV[0].eql? '2')
	Connection::connect()
	Connection::last_connection_broadcast()
else
	puts "wrong arguments. :("
	exit
end

Thread.list.each { |thr| thr.join if thr != Thread.main}
#connection established
puts "NODE #{$node_id} READY"

unless($left_client.nil?)
	Connection::left_listener()
end

unless($right_client.nil?)
	Connection::right_listener()
end

Thread.list.each { |thr| thr.join if thr != Thread.main}