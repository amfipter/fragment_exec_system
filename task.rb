class Task
	attr_reader :dest_id, :data_deps, :priority
  attr_accessor :name
	def initialize(dest_id, exec=nil, p = 0)
		@dest_id = dest_id
		@name = ''
    @data_deps = Array.new
    @priority = p
    @code = Array.new
    @execution_code = exec
    @output_data = nil
	end

  def add_data_dep(data_id)
    @data_deps.push data_id
    nil
  end

	def to_s()
		"name: #{@name}; dest_id: #{@dest_id}"
	end

  def getInputDFs()
    @data_deps
  end

  def run(input_data)
    @output_data = @execution_code.call(input_data)
    @output_data
  end
end
