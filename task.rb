class Task
	attr_reader :dest_id, :data_deps
	def initialize(dest_id)
		@dest_id = dest_id
		@name = ''
    @data_deps = Array.new
	end

  def add_data_dep(data_id)
    @data_deps.push data_id
    nil
  end

	def to_s()
		"name: #{@name}; dest_id: #{@dest_id}"
	end
end
