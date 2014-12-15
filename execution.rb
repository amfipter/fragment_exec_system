class Execution
	def initialize()
		nil
	end

	def run()
		test()
		Misc::task_sender()
		puts 'READY'
		nil
	end

	def test()
		if($node_id == 0)
			5.times do 
				$task_stack.push Task.new(Random.rand(0..2))
			end
		end
	end
end