module Misc
	def self.data_task_deser(ser_data)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::data_task_deser".green if $debug_trace
		#check
		$mutex.lock
		if(ser_data =~ /^Data\s/)
			# puts ser_data.red 
			data = Data_.new_deserialize(ser_data)
			puts "GET DATA #{data.to_s}" if $debug_trace
			$data_stack.push data
		end
		if(ser_data =~ /^Task\s/)
			puts "GET TASK" if $debug_trace
			$task_stack.push Task.new_deserialize(ser_data)
		end
		$mutex.unlock
		nil
	end

	#old
	def self.send_ser(data, dest, command)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::send_ser #{data.serialize}".green if $debug_trace
		Connection::send(dest, command, data.serialize)
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
		puts from.upcase.red 

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
		puts "#{Thread.current.thread_variable_get("id")}: Misc::task_sender".green if $debug_trace
		del = Array.new
		$mutex.lock
		$task_stack.each do |t|
			if(t.dest_id != $node_id)
				# $task_stack.delete t
				del.push t
				Misc::send_ser(t, t.dest_id, 'transfer')
			end
		end
		del.each do |el|
			$task_stack.delete el 
		end
		$mutex.unlock
		nil
	end

	def self.data_sender()
		puts "#{Thread.current.thread_variable_get("id")}: Misc::data_sender".green if $debug_trace
		del = Array.new 
		$mutex.lock 
		$data_stack.each do |data|
			dest = Misc::get_dest_from_id(data.id)
			if(dest != $node_id and data.move_flag)
				del.push data 
				Misc::send_ser(data, dest, 'transfer')
			end
		end
		del.each do |data|
			$data_stack.delete data 
		end
		$mutex.unlock 
		nil
	end

	def self.data_search(id)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::data_search".green if $debug_trace
		$mutex.lock 
		$data_stack.each do |d|
			if(d.id.eql? id )
				$data_stack.delete d if $delete_data_copies
				$mutex.unlock
				return d
			end
		end
		$mutex.unlock
		nil
	end

	def self.remove_data_src(id)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::remove_data_src".green if $debug_trace
		dest = Misc::get_dest_from_id(id)
		if(dest == $node_id)
			Misc::remove_data(id)
		else
			Connection::send('left', 'remove', id) if dest < $node_id
			Connection::send('right', 'remove', id) if dest > $node_id
		end
		nil
	end

	def self.remove_data(id)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::remove_data #{id}".green if $debug_trace
		$mutex.lock 
		$data_stack.each do |d|
			if(d.id.eql? id )
				$data_stack.delete d 
				break
			end
		end
		$mutex.unlock
		nil
	end

	def self.get_data_locked(id)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::get_data_locked #{id} #{Misc::get_dest_from_id(id)}".green if $debug_trace
		data = Misc::get_data(id)
		while(data.nil?)
			sleep 1.0/50
			data = Misc::get_data(id)
		end
		data
	end

	def self.get_data(id)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::get_data #{id} #{Misc::get_dest_from_id(id)}".magenta if $debug_trace
		$mutex.lock
		$data_stack.each do |data|
			if(data.id.eql? id)
				$mutex.unlock
				return data 
			end
		end
		$mutex.unlock

		$data_accept = false
		dest = Misc::get_dest_from_id(id)
		return nil if dest == $node_id
		Connection::send('left', "get_data#{$node_id}", id) if dest < $node_id
		Connection::send('right', "get_data#{$node_id}", id) if dest > $node_id
		sleep 1.0/10 until $data_accept

		$mutex.lock
		$data_stack.each do |data|
			if(data.id.eql? id)
				$mutex.unlock
				return data 
			end
		end
		$mutex.unlock
		return nil
	end

	def self.data_ready?(data_list)
		puts "#{Thread.current.thread_variable_get("id")}: Misc::data_ready?".green if $debug_trace
		out = true
		if($data_stack.size == 0)
			return false
		end
		$mutex.lock 
		data_list.each do |id|
			$data_stack.each do |data|
				break if data.id.eql? id 
				out = false 
			end
		end
		$mutex.unlock
		out 
	end

	def self.kill()
		puts "KILLED.".red
		if($debug_trace)
			Thread.list.each do |t|
				puts t.thread_variable_get("id").to_s.red
				puts t.backtrace
			end
		end
		Connection::send("left", 'kill', 'nil')
		Connection::send("right", 'kill', 'nil')
		exit()
	end

	def self.restore_task(id)
		#why?
		while($head_task.nil?)
			sleep 1.0/10
		end
		return $head_task.restore_task(id)
	end

	def self.sort_task()
		$mutex.lock
		$task_stack.sort! {|x, y| x.priority <=> y.priority}
		$mutex.unlock
	end

	def self.get_dest_from_id(id)
		dest = 0
		id.each_char {|c| dest += c.ord}
		dest = dest % ($node_count)
		dest 
	end

	def self.resolve_data_dep_locked(data_dep_list)
		data_dep_list.each {|data| puts "SEARCH: #{data}".red} if $debug_trace
		data_dep_list.each do |id|
			Misc::get_data_locked(id)
		end
		nil
	end

	def self.resolve_data_dep(data_dep_list)
		data_dep_list.each do |id|
			data = Misc::get_data(id)
			return false if data.nil?
		end
		true
	end

	def self.task_map(tasks)
		tasks.each do |task|
			$task_map[task.id] = task
		end
		nil
	end

	def self.clear_data(id_pattern)
		del = Array.new 
		$data_stack.each {|data| del.push data if data =~ /#{id_pattern}/}
		del.each {|data| $data_stack.delete data}
		nil 
	end
end


class Matrix
	attr_reader :dim, :data
	def initialize(dim, slices, empty=false)
		@data = Array.new(dim) {|el| el = Array.new(dim) {|el1| el1 = 0}}
		@dim = dim
		@slices = slices
		init() unless empty
		# print_
	end

	def init()
		@dim.times do |i|
			@dim.times do |j|
				@data[i][j] = i*@dim + j
			end
		end
	end

	def slice_out(s_i, s_j)
		out = Matrix.new(@dim/@slices, 1)
		size = @dim/@slices
		(s_i*size).upto((s_i + 1)*size -1) do |i|
			(s_j*size).upto((s_j + 1)*size -1) do |j|
				# puts "#{i} #{j}"
				out.set(i-s_i*size, j-s_j*size, @data[i][j])
			end
		end
		out
	end

	def slice_in(s_i, s_j, slice)
		size = @dim/@slices
		(s_i*size).upto((s_i + 1)*size -1) do |i|
			(s_j*size).upto((s_j + 1)*size -1) do |j|
				@data[i][j] = slice.data[i-s_i*size][j-s_j*size]
			end
		end
	end

	def self.mul_part(m1, m2)
		out = Matrix.new(m1.dim, 1)
		m1.dim.times do |i|
			m1.dim.times do |j|
				out.set(i, j, 0)
				m1.dim.times do |k|
					out.add(i, j, m1.data[i][k]*m2.data[k][j])
				end
			end
		end
		out 
	end

	def self.add_part(m1, m2)
		m1.dim.times do |i|
			m1.dim.times do |j|
				m1.add(i, j, m2.data[i][j])
			end
		end
	end

	def set(i, j, d)
		# puts "#{i} #{j}"
		@data[i][j] = d
	end

	def add(i, j, d)
		@data[i][j] += d
	end

	def print_()
		@dim.times do |i|
			@dim.times do |j|
				print "#{@data[i][j]} "
			end
			puts ''
		end
		puts ''
		return nil
	end

	def to_s()
		out = ''
		@dim.times do |i|
			@dim.times do |j|
				out += "#{@data[i][j]} "
			end
			out += "\n"
		end
		out += "\n"
		out
	end

	def serialize()
		"#{@dim} #{@slices} #{@data.to_s}"
	end

	def deserialize(str)
		str = str.split ' '
		@dim = str.shift.to_i
		@slices = str.shift.to_i
		str = str.join ' '
		@data = eval str
		return nil
	end

	def self.new_deserialize(str)
		obj = new(1, 1, 1)
		obj.deserialize(str)
		obj
	end

end

class FakeMutex
	def initialize()
		nil
	end

	def lock()
		nil
	end

	def unlock()
		nil 
	end

	def locked?()
		false
	end
end