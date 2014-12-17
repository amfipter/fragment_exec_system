require 'socket'
module Connection
  def self.broadcast()
  	puts 'Connection::broadcast' if $debug_trace
	  Thread.new do
	    addr = ['<broadcast>', 33333]# broadcast address
			#addr = ('255.255.255.255', 33333) # broadcast address explicitly [might not work ?]
			#addr = ['127.0.0.255', 33333] # ??
			udp = UDPSocket.new
			udp.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
			data = $out_port.to_s
			while($broadcast)
				udp.send(data, 0, addr[0], addr[1])
				sleep 1.0/3
			end
			udp.close
		end
		nil
  end

  def self.connect()
  	puts 'Connection::connect' if $debug_trace
		addr = ['0.0.0.0', 33333]  # host, port
		BasicSocket.do_not_reverse_lookup = true
		# Create socket and bind to address
		udp = UDPSocket.new
		udp.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
		udp.bind(addr[0], addr[1])

		data, addr = udp.recvfrom(1024) # if this number is too low it will drop the larger packets and never give them to you
		puts "From addr: '%s', msg: '%s'" % [addr[2], data]
		udp.close
		$out_port = data.to_i + 1
		$node_id = $out_port - 30000
		$left_client = TCPSocket.open(addr[2], data.to_i)
		puts 'connected: ' + addr[2].to_s + ' ' + data
		nil
  end

  def self.wait_last_connection()
  	puts 'Connection::wait_last_connection' if $debug_trace
  	addr = ['0.0.0.0', 33334]  # host, port
		BasicSocket.do_not_reverse_lookup = true
		# Create socket and bind to address
		udp = UDPSocket.new
		udp.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
		udp.bind(addr[0], addr[1])
		data, addr = udp.recvfrom(1024)
		until(data =~ /last_(\d+)/)
			data, addr = udp.recvfrom(1024)
		end
    $node_count = $1.to_i
		udp.close
		nil
  end

  def self.last_connection_broadcast()
  	puts 'Connection::last_connection_broadcast' if $debug_trace
  	addr = ['<broadcast>', 33334]# broadcast address
		#addr = ('255.255.255.255', 33333) # broadcast address explicitly [might not work ?]
		#addr = ['127.0.0.255', 33333] # ??
		udp = UDPSocket.new
		udp.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
		udp.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
		data = 'last_' + ($node_id + 1).to_s
		udp.send(data, 0, addr[0], addr[1])
		udp.close
    $node_count = $node_id + 1
		nil
	end

  def self.create_connection()
  	puts 'Connection::create_connection' if $debug_trace
    Thread.new do 
    	server = TCPServer.open($out_port)
    	puts "TCP started at " + $out_port.to_s
    	$right_client = server.accept
    	$broadcast = false
    end
    nil
  end

  def self.command_parser(command, data, from)
  	puts 'Connection::command_parser' if $debug_trace
  	puts "get command: " + command
  	if(command =~ /transfer(\d+)/)
  		dest = $1.to_i
  		if(dest == $node_id)
  			Misc::data_task_deser(data)
  			return nil
  		else
  			Connection::send(dest, 'transfer', data)
  			return nil
  		end
  	end

  	if(command.eql? 'status')
  		Misc::status(from)
  	end

  	# if(command =~ /get_data(\d+)/)
  	# 	dest = $1.to_i
  	# 	data_part = Misc::data_search(data.to_i)
  	# 	unless(data_part.nil?)
  	# 		Misc::send_ser(data_part, dest, 'transfer')
  	# 	else
  	# 		if(from.eql? 'left')
  	# 			if($right_client.nil?)
  	# 				Connection::send(dest, 'transfer', 'data_not_found')
  	# 			else
  	# 				Connection::send('right', command, data)
  	# 			end
  	# 		else
  	# 			if($left_client.nil?)
  	# 				Connection::send(dest, 'transfer', 'data_not_found')
  	# 			else
  	# 				Connection::send('left', command, data)
  	# 			end
  	# 		end
  	# 	end
  	# end

    if(command =~ /get_data_(\d+)_(\d+)/)
      src = $1 
      dest = $2 
      if(dest != $node_id) 
        Connection::send(dest, "get_data_#{src}_", data)
      else
        data_part = Misc::data_search(data)
        Connection::send(src, 'put_data', 'nil') if data_part.nil?
        Misc::send_ser(data_part, src, 'put_data')
      end
      return nil
    end

    if(command =~ /put_data(\d+)/)
      dest = $1 
      if(dest != $node_id)
        Connection::send(dest, 'put_data', data)
      else
        if(data.eql? 'nil')
          $data_accept = true
        else
          $data_accept = true
          Misc::data_task_deser(data)
        end
      end
      return nil
    end


    if(command.eql? 'kill')
      Connection::send('left', 'kill', data) if from.eql? 'right'
      Connection::send('right', 'kill', data) if from.eql? 'left'
      puts "KILLED."
      exit()
    end

  end

  def self.left_listener
  	puts 'Connection::left_listener' if $debug_trace
  	Thread.new do 
  		while($lisnener_work) do
  			command = $left_client.gets.chomp
  			data = $left_client.gets.chomp
        # Misc::wait_for_mutex()
        # $mutex.lock
    		Connection::command_parser(command, data, 'left')
        # $mutex.unlock
  		end
  	end
  	nil
  end

  def self.right_listener
  	puts 'Connection::right_listener' if $debug_trace
  	Thread.new do 
  		while($lisnener_work) do
  			command = $right_client.gets.chomp
  			data = $right_client.gets.chomp
        # Misc::wait_for_mutex()
        # $mutex.lock
    		Connection::command_parser(command, data, 'right')
        # $mutex.unlock
  		end
  	end
  	nil
  end

  def self.send(dest, command, data)
  	puts "Connection::send #{dest}; #{command}" if $debug_trace
  	if(dest.class.eql? Fixnum)
  		if(dest < $node_id)
  			unless($left_client.nil?)
	  			$left_client.puts command + dest.to_s
	  			$left_client.puts data
	  		end
  		elsif(dest > $node_id)
  			unless($right_client.nil?)
	  			$right_client.puts command + dest.to_s
	  			$right_client.puts data
	  		end
  		else
  			puts 'Fixnum destination error.'
  		end
  	end

  	if(dest.class.eql? String)
  		if(dest.eql? 'left')
  			unless($left_client.nil?)
	  			$left_client.puts command
	  			$left_client.puts data
	  		end
  		elsif(dest.eql? 'right')
  			unless($right_client.nil?)
	  			$right_client.puts command
	  			$right_client.puts data
	  		end
  		else
  			puts 'String destination error.'
  		end
  	end
  	nil
  end
  				
end