class Execution
	def initialize()
		nil
	end

	def run()
		matrix_mul()
		# test3()
		# $lisnener_work = false
		nil
	end

	def matrix_mul()
		matrix_head_task = Matrix_mul_generator.new(3)
		# matrix_head_task.random_m_dist()
		# matrix_head_task.random_s_dist()
		tasks = matrix_head_task.generate_tasks()
		puts tasks.size.to_s.blue
		Misc::task_map(tasks)
		if($node_id == 0)
			$task_stack = tasks
			$data_stack = matrix_head_task.generate_data()
			Misc::task_sender()
			Misc::data_sender()
		end
		
		sleep 1
		group = -1
		while($task_stack.size == 0)
			puts "waiting".green
			sleep 1 
		end
		Misc::sort_task()

		while(true) do 
			task = $task_stack.shift
			dep_resolve = Misc::resolve_data_dep(task.getInputDFs())
			unless(dep_resolve)
				$task_stack.push task
				next 
			end
			input_data = Array.new
			task.getInputDFs.each do |id|
				input_data.push Misc::get_data(id)
			end
			input_data.reverse!
			puts "EXECUTING #{task.name} #{task.id}".red 
			output_data = task.run(input_data)
			puts "\tDONE".red
			$data_stack.push output_data unless output_data.nil?
			Misc::data_sender()
			sleep 1.0/100
		end
	end

	#task transfer test
	def test1()
		if($node_id == 0)
			5.times do 
				$task_stack.push Task.new(Random.rand(0..2), nil)
			end
		end
	end

	#data transfer test
	def test2()
		if($node_id == 0)
			$data_stack.push Data_.new(1)
		elsif($node_id == 2)
			Misc::get_data(1)
		end
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

	

end