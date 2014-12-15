#!/usr/bin/env ruby
require './connect.rb'
require './misc.rb'
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
$debug_trace = true
$lisnener_work = true
$data_accept = false
$data_not_found = 0

$delete_data_copies = true

exit

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

Signal.trap("TSTP") do
	Misc::status()
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

e = Execution.new 
e.run

Thread.list.each { |thr| thr.join if thr != Thread.main}