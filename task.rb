class Task
	def initialize(dest_id)
		@dest_id = dest_id
		@name = ''
	end

	def dest_id()
		@dest_id
	end

	def to_s()
		"name: #{@name}; dest_id: #{@dest_id}"
	end
end
