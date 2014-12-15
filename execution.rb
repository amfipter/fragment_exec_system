class Execution
	def initialize()
		nil
	end

	def run()
		test3()
		Misc::task_sender()
		puts 'READY'
		nil
	end

	#task transfer test
	def test1()
		if($node_id == 0)
			5.times do 
				$task_stack.push Task.new(Random.rand(0..2))
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
		if($node_id == 0)
			$data_stack.push Data_.new(1)
			$data_stack.push Data_.new(2)
			t = Task.new(2)
			t.add_data_dep(1)
			t.add_data_dep(2)
			$task_stack.push t
		elsif($node_id == 2)
			while($task_stack.size == 0)
				sleep 1.0/100
			end
			Misc::resolve_data_dep($task_stack[0].data_deps)
		end
	end

	

end