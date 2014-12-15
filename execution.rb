class Execution
	def initialize()
		nil
	end

	def run()
		test2()
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
end