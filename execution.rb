class Execution
	def initialize()
		nil
	end

	def run()
		matrix_mul()
		# test3()
		# Misc::task_sender()
		nil
	end

	def matrix_mul()
		matrix_head_task = Matrix_mul_generator.new(3)
		matrix_head_task.random_m_dist()
		matrix_head_task.random_s_dist()
		tasks = matrix_head_task.generate_tasks()
		Misc::task_map(tasks)
		if($node_id == 0)
			$task_stack = tasks
			$data_stack = matrix_head_task.generate_data()
		end
		Misc::task_sender()
		Misc::data_sender()
		while(true) do 
			sleep 1.0/10 while $task_stack.size == 0
			Misc::sort_task()
			$task_stack.each do |task|
				Misc::resolve_data_dep(task.getInputDFs())
			end
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
	end

	

end