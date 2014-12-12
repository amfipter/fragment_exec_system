require './connect.rb'

$broadcast = true
$out_port = 30000
$left_client = nil
$right_client = nil

if(ARGV[0].eql? '0')
	puts '0'
	Connection::broadcast()
	Connection::connect()
elsif(ARGV[0].eql? '1')
	puts '1'
	Connection::connection()
	Connection::broadcast()
	Connection::connect()
elsif(ARGV[0].eql? '2')
	Connection::connection()
end

Thread.list.each { |thr| thr.join if thr != Thread.main}

