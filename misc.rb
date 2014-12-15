module Misc
	def self.data_task_deser(ser_data)
		data = Marshal.load(ser_data)
		$data_stack.push data if data.class.eql? Data 
		$task_stack.push data if data.class.eql? Task
		nil
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
end
