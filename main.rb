#!/usr/bin/env ruby
require 'colorize'
require './connect.rb'
require './misc.rb'
require './execution.rb'
require './data.rb'
require './task.rb'
# require './matrix_mul_module.rb'

exec_option = ARGV.shift
fabric_name = ARGV.shift
fabric_args = ARGV

require "./#{fabric_name}.rb"

#local search
#delete data fragment

$broadcast = true
$out_port = 30000
$left_client = nil
$right_client = nil
$mutex = FakeMutex.new
$node_id = nil
$node_count = -1
$task_stack = Array.new
$data_stack = Array.new
$debug_trace = true
$lisnener_work = true
$data_accept = false
$data_not_found = 0
$task_map = Hash.new
$head_task_node = 0
$head_task = nil

$delete_data_copies = false

Thread::abort_on_exception = true

if(exec_option.eql? '0')
	puts '0'
	Connection::broadcast()
	Connection::create_connection()
	Connection::wait_last_connection()
	$node_id = 0
elsif(exec_option.eql? '1')
	puts '1'
	Connection::connect()
	Connection::broadcast()
	Connection::create_connection()
	Connection::wait_last_connection()
elsif(exec_option.eql? '2')
	Connection::connect()
	Connection::last_connection_broadcast()
else
	puts "wrong arguments. :("
	exit
end

Signal.trap("TSTP") do
	Misc::status()
end

Signal.trap("INT") do 
	Misc::kill()
end

Thread.list.each { |thr| thr.join if thr != Thread.main}
Thread.current.thread_variable_set(:id, 0)
#connection established
puts "NODE #{$node_id} READY #{$node_count}"


unless($left_client.nil?)
	Connection::left_listener()
end

unless($right_client.nil?)
	Connection::right_listener()
end

e = Execution.new 
fabric_name = fabric_name[0].upcase + fabric_name[1..fabric_name.length-1]
$head_task = Module.const_get(fabric_name).new(fabric_args)
e.universal_execute($head_task)

Thread.list.each { |thr| thr.join if thr != Thread.main}