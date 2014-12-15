module Misc
	def self.data_task_deser(ser_data)
		puts 'Misc::data_task_deser' if $debug_trace
		Misc::wait_for_mutex()
		$mutex.synchronize do 
			if(ser_data.eql? 'data_not_found')
				$data_not_found += 1
				return nil
			end
			data = Marshal.load(eval(ser_data))
			if (data.class.eql? Data)
				$data_stack.push data 
				$data_accept = true
			end
			$task_stack.push data if data.class.eql? Task
		end
		nil
	end

	def self.send_ser(data, dest, command)
		puts 'Misc::send_ser' if $debug_trace
		ser_data = Marshal.dump(data).dump
		Connection::send(dest, command, ser_data)
	end

	def self.status(from = '')
		puts '='*20
		puts "Task stack:"
		puts "Count: " + $task_stack.size.to_s
		$task_stack.each do |t|
			puts t.to_s
		end
		puts ''
		puts "Data stack:"
		puts "Count: " + $data_stack.size.to_s
		$data_stack.each do |t|
			puts t.to_s
		end
		puts '='*20

		if(from.eql? '')
			Connection::send('left', 'status', 'nil')
			Connection::send('right', 'status', 'nil')
		elsif(from.eql? 'right')
			Connection::send('left', 'status', 'nil')
		elsif(from.eql? 'left')
			Connection::send('right', 'status', 'nil')
		end
	end

	def self.task_sender()
		puts 'Misc::task_sender' if $debug_trace
		$task_stack.each do |t|
			if(t.dest_id != $node_id)
				$task_stack.delete t
				Misc::send_ser(t, t.dest_id, 'transfer')
			end
		end
	end

	def self.data_search(id)
		$data_stack.each do |d|
			return d if d.id == id 
		end
		nil
	end

	def self.get_data(id)
		if($left_client.nil? or $right_client.nil?)
			$data_not_found = 1
		end
		Connection::send('left', 'get_data'+$node_id.to_s)
		#UNCOMPLETE
	end

	def self.wait_for_mutex()
		while($mutex.locked?)
			sleep 1.0/100
		end
	end
end
