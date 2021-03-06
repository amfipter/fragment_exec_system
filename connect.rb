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
			data = $out_port.to_s  + ' ' + Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address
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
		port = $1 if data =~ /^(\d+)\s/
		$out_port = port.to_i + 1
		$node_id = $out_port - 30000
		$left_client = TCPSocket.open(addr[2], port.to_i)
		puts 'connected: ' + addr[2].to_s + ' ' + port
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
    	puts __LINE__
    	$broadcast = false
    end
    nil
  end

  def self.command_parser(command, data, from)
  	puts "#{Thread.current.thread_variable_get("id")}: Connection::command_parser".magenta if $debug_trace
  	puts "get command: #{command} #{data}".magenta  if $debug_trace
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

    if(command =~ /get_data(\d+)/)
      src = $1.to_i
      dest = Misc::get_dest_from_id(data)
      if(dest != $node_id) 
        Connection::send('left', "get_data#{src}", data) if dest < $node_id
        Connection::send('right', "get_data#{src}", data) if dest > $node_id
      else
        data_part = Misc::data_search(data)
        Connection::send(src, 'put_data', 'nil') if data_part.nil?
        Misc::send_ser(data_part, src, 'put_data') unless data_part.nil?
      end
      return nil
    end

    if(command =~ /put_data(\d+)/)
      dest = $1.to_i
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

    #old
    if(command.eql? 'remove_all')
      Misc::remove_data(data)
      Connection::send('left', 'remove_all', data) if from.eql? 'right'
      Connection::send('right', 'remove_all', data) if from.eql? 'left'
      return nil
    end

    #old
    if(command =~ /remove(\d+)/)
      dest = $1.to_i
      if(dest == $node_id)
        Misc::remove_data(data)
      else 
        Connection::send(dest, 'remove', data)
      end
      return nil
    end

    if(command.eql? "remove")
      dest = Misc::get_dest_from_id(data)
      if(dest == $node_id)
        Misc::remove_data(data)
      else
        Connection::send('left', 'remove', data) if dest < $node_id
        Connection::send('right', 'remove', data) if dest > $node_id
      end
      return nil
    end


    if(command.eql? 'kill')
    	if($debug_trace)
				Thread.list.each do |t|
					puts t.thread_variable_get("id").to_s.red
					puts t.backtrace
				end
			end
			puts "KILLED.".red
      Connection::send('left', 'kill', data) if from.eql? 'right'
      Connection::send('right', 'kill', data) if from.eql? 'left'
      exit()
    end

  end

  def self.left_listener
  	puts 'Connection::left_listener' if $debug_trace
  	t = Thread.new do 
  		Thread.current.thread_variable_set(:id, 1)
  		while($lisnener_work) do
  			# puts "LEFT READY".cyan
  			command = $left_client.gets.chomp
  			data = $left_client.gets.chomp
  			puts "LEFT: #{command}".blue if $debug_trace
        # Misc::wait_for_mutex()
        # $mutex.lock
    		Connection::command_parser(command, data, 'left')
        # $mutex.unlock
  		end
  		puts 'LEFT THREAD FAIL'.red 
  		exit
  	end
  	t
  end

  def self.right_listener
  	puts 'Connection::right_listener' if $debug_trace
  	t = Thread.new do 
  		Thread.current.thread_variable_set(:id, 2)
  		while($lisnener_work) do
  			# puts "RIGHT READY".cyan
  			command = $right_client.gets.chomp
  			data = $right_client.gets.chomp
  			puts "RIGHT: #{command}".blue if $debug_trace
        # Misc::wait_for_mutex()
        # $mutex.lock
    		Connection::command_parser(command, data, 'right')
        # $mutex.unlock
  		end
  		puts 'RIGHT THREAD FAIL'.red 
  		exit
  	end
  	t
  end

  def self.send(dest, command, data)
  	puts "#{Thread.current.thread_variable_get("id")}: Connection::send #{dest}; #{command}" if $debug_trace
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