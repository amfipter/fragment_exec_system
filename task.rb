class Task
	attr_reader :dest_id
	def initialize(dest_id)
		@dest_id = dest_id
		@name = ''
	end

	def to_s()
		"name: #{@name}; dest_id: #{@dest_id}"
	end
end
