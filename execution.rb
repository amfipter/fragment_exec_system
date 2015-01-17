class Execution
	def initialize()
		nil
	end

	#internal method for tests and execution
	def run()
		matrix_mul()
		# test3()
		nil
	end

	#universal execution method 
	def universal_execute(head_task)
		tasks = head_task.generate_tasks()
		Misc::task_map(tasks)

		if($node_id == $head_task_node)
			$task_stack = tasks 
			$data_stack = head_task.generate_data()
			Misc::task_sender()
			Misc::data_sender()
		end

		while($task_stack.size == 0)
			puts "waiting".green
			sleep 1.0/10
		end

		Misc::sort_task()

		while($task_stack.size > 0) do 
			task = $task_stack.shift
			input_data = Array.new
			Misc::resolve_data_dep_locked(task.getInputDFs())
			task.getInputDFs.each do |id|
				input_data.push Misc::get_data(id)
			end
			input_data.reverse!
			puts "EXECUTING #{task.name} #{task.id}".red 
			out = task.run(input_data)
			puts "\tDONE".red
			output_data = out.shift 
			output_tasks = out.shift
			$data_stack.push output_data unless output_data.size == 0
			$task_stack.push output_tasks unless output_tasks.size == 0
			Misc::data_sender()
			Misc::task_sender()
			Misc::sort_task()
		end
		puts "DONE".red
		if($node_id == 0)
			Misc::kill
		end
		nil
	end

	def matrix_mul()
		matrix_head_task = Matrix_mul_generator.new(3)
		$head_task = matrix_head_task
		tasks = matrix_head_task.generate_tasks()
		puts tasks.size.to_s.blue
		Misc::task_map(tasks)
		puts $task_map.keys.size
		if($node_id == 0)
			$task_stack = tasks
			$data_stack = matrix_head_task.generate_data()
			Misc::task_sender()
			Misc::data_sender()
		end
		
		# sleep 1
		group = -1
		while($task_stack.size == 0)
			puts "waiting".green
			sleep 1.0/10
		end
		Misc::sort_task()

		while($task_stack.size > 0) do 
			# if($task_stack.size <= 3)
			# 	Misc::remove_m_data()
			# end
			task = $task_stack.shift
			# dep_resolve = Misc::resolve_data_dep(task.getInputDFs())
			# unless(dep_resolve)
			# 	$task_stack.push task
			# 	next 
			# end
			input_data = Array.new
			Misc::resolve_data_dep_locked(task.getInputDFs())
			task.getInputDFs.each do |id|
				input_data.push Misc::get_data(id)
			end
			input_data.reverse!
			puts "EXECUTING #{task.name} #{task.id}".red 
			out = task.run(input_data)
			puts "\tDONE".red
			output_data = out.shift 
			output_tasks = out.shift
			$data_stack.push output_data unless output_data.size == 0
			$task_stack.push output_tasks unless output_tasks.size == 0
			Misc::data_sender()
			Misc::task_sender()
			Misc::sort_task()
			# sleep 1.0/100
		end
		puts "DONE".red
		if($node_id == 0)
			Misc::kill
		end
		nil
	end

	#task transfer test
	def test1()
		if($node_id == 0)
			5.times do 
				$task_stack.push Task.new(Random.rand(0..2), nil)
			end
		end
		nil
	end

	#data transfer test
	def test2()
		if($node_id == 0)
			$data_stack.push Data_.new(1)
		elsif($node_id == 2)
			Misc::get_data(1)
		end
		nil
	end

	#resolve task deps test
	def test3()
		t = Task.new(2, '1')
		t.add_data_dep('1')
		t.add_data_dep('2') 
		$task_map[t.id] = t
		if($node_id == 0)
			$data_stack.push Data_.new('1')
			$data_stack.push Data_.new('2')
			$task_stack.push t
			Misc::data_sender()
		elsif($node_id == 2)
			while($task_stack.size == 0)
				sleep 1.0/100
			end
			Misc::resolve_data_dep($task_stack[0].data_deps)
			puts 'REMOVING DATA 1 AFTER 3 SEC'
			sleep 3
			Misc::remove_data_src('1')
			puts 'REMOVING DATA 2 AFTER 3 SEC'
			sleep 3
			Misc::remove_data_src('2')
			puts 'ALL CLEAR'
		end
		Misc::task_sender()
	end
	nil
end