class Matrix_mul_generator
	def initialize(node_count, matrix_dim = 9, slices = 3)
		@node_count = node_count
		@matrix_dim = matrix_dim
		@slices = slices
		@matrix = Matrix.new(matrix_dim, slices)
		@s_fragment_dist = [
			0, 1, 2,
			2, 1, 0,
			1, 0, 2
		]
		@m_fragment_dist = [
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
			x = $1 if m1.id =~ /1m_\d+_(\d+)/			# i j
			y = $1 if m2.id =~ /2m_\d+_(\d+)/			# i k
			#z = $1 if m2.id =~ /1m_(\d+)_\d+/			# k j
			out = Data_.new("c_#{y}_#{x}_#{y}", m_out)	#k j k
		end
	end

	def set_s_exec()
		@s_exec = Proc.new do |input_data|
			m1 = input_data.pop
			m1_id = m1.id 
			m1 = m1.data 
			input_data.each do |m|
				Matrix::add_part(m1, m)
			end
			x = $1 if m1_id =~ /c_(\d+)_\d+/
			y = $1 if m1_id =~ /c_\d+_(\d+)/
			out = Data_.new("out_#{x}_#{y}", m1)
			out 
		end
	end

	def set_out_exec()
		@out_exec = Proc.new do |input_data|
			size = Math::sqrt(input_data.size) * input_data[0].data.data.size
			m = Matrix.new(size, Math::sqrt(input_data.size))
			input_data.each do |t|
				x = $1 if t.id =~ /out_(\d+)/
				y = $1 if t.id =~ /out_\d+_(\d+)/
				m.slice_in(x.to_i, y.to_i, t.data)
			end
			out = Data_.new('result')
			out 
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

	def generate_s_tasks()
		s_tasks = Array.new 
		@slices.times.do |i|
			@slices.times do |j|
				t = Task.new(@s_fragment_dist[i*@slices + j], @s_exec, 1)
				t.name = "S_FRAGMENT"
				@slices.times do |k|
					t.add_data_dep("c_#{i}_#{j}_#{k}")
				end
				s_tasks.push t 
			end
		end
		s_tasks
	end

	def generate_out_tasks()
		out_tasks = Array.new
		t = Task.new(0, @out_exec, 2)
		@slices.times do |i|
			@slices.times do |j|
				t.add_data_dep("out_#{i}_#{j}")
			end
		end
		out_tasks.push t 
		out_tasks
	end


	def generate_m_tasks()
		m_tasks = Array.new
		@slices.times do |i|
			@slices.times do |j|
				@slices.times do |k|
					t = Task.new(@m_fragment_dist[i*@slices**2 + j*@slices + k], @m_exec, 0)
					t.add_data_dep("1m_#{i}_#{j}")
					t.add_data_dep("2m_#{i}_#{k}")
					m_tasks.push t 
				end
			end
		end
		m_tasks
	end

	def generate_data()
		matrix_data = Array.new
		m1 = Matrix.new(@matrix_dim, @slices)
		m2 = Matrix.new(@matrix_dim, @slices)
		@slices.times do |i|
			@slices.times do |j|
				matrix_data.push Data_.new("1m_#{i}_#{j}", m1.slice_out(i,j))
				matrix_data.push Data_.new("2m_#{i}_#{j}", m2.slice_out(i,j))
			end
		end
		matrix_data
	end

end


