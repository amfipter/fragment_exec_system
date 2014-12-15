class Matrix_mul_generator
	def initialize(node_count, matrix_dim = 9, slices = 3)
		@node_count = node_count
		@matrix_dim = matrix_dim
		@slices = slices
		@matrix = Matrix.new(matrix_dim, slices)
		@m_fragment_dist = [
			0, 1, 2,
			2, 1, 0,
			1, 0, 2
		]
		@s_fragment_dist = [
			1, 2, 0,
			0, 2, 1,
			0, 1, 2,

			0, 1, 2,
			2, 1, 0,
			1, 0, 2,

			1, 1, 1,
			2, 2, 2,
			0, 0, 0
		]
		if(slices != 3)
			random_s_dist()
			random_m_dist()
		end
	end

	def set_manual_m_dist(m_dist)
		@m_fragment_dist = m_dist
	end

	def set_manual_s_dist(s_dist)
		@s_fragment_dist = s_dist
	end

	def set_m_exec()
		@m_exec = Proc.new do |input_data|
			m1 = input_data.pop.data 
			m2 = input_data.pop.data 
			m_out = Matrix::mul_part(m1, m2)
			x = $1 if m1.id =~ /1m_(\d+)_\d+/
			y = $1 if m2.id =~ /1m_\d+_(\d+)/
			z = $1 if m2.id =~ /1m_(\d+)_\d+/
			out = Data_.new("c_#{x}_#{y}_#{z}", m_out)
		end
	end

	def random_m_dist()
		r = Random.new
		@m_fragment_dist = Array.new 
		(@matrix_dim**2).times do
			@m_fragment_dist.push r.rand(0..@node_count-1)
		end
	end

	def random_s_dist()
		r = Random.new
		@s_fragment_dist = Array.new 
		(@matrix_dim**3).times do
			@s_fragment_dist.push r.rand(0..@node_count-1)
		end
	end

	def generate_m_tasks()
		m_tasks = Array.new
		#UNCOMPLETE
	end
end


