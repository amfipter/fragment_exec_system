require 'socket'
module Connection
  def self.broadcast()
	  	t = Thread.new do
	    addr = ['<broadcast>', 33333]# broadcast address
		#addr = ('255.255.255.255', 33333) # broadcast address explicitly [might not work ?]
		#addr = ['127.0.0.255', 33333] # ??
		udp = UDPSocket.new
		udp.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
		data = $out_port.to_s
		while($broadcast)
			udp.send(data, 0, addr[0], addr[1])
			sleep 1
		end
		udp.close
	end
	# t.join
  end

  def self.connection()
	addr = ['0.0.0.0', 33333]  # host, port
	BasicSocket.do_not_reverse_lookup = true
	# Create socket and bind to address
	udp = UDPSocket.new
	udp.bind(addr[0], addr[1])
	data, addr = udp.recvfrom(1024) # if this number is too low it will drop the larger packets and never give them to you
	puts "From addr: '%s', msg: '%s'" % [addr[2], data]
	udp.close
	$out_port = data.to_i + 1

	$left_client = TCPSocket.open(addr[2], data.to_i)
	puts 'connected: ' + addr[2].to_s + ' ' + data
  end

  def self.connect()
    t = Thread.new do 
    	server = TCPServer.open($out_port)
    	puts "TCP started at " + $out_port.to_s
    	$right_client = server.accept
    	$broadcast = false
    end
    # t.join
  end
end