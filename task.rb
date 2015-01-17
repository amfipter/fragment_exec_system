class Task
	attr_reader :dest_id, :data_deps, :priority, :id
  attr_accessor :name
	def initialize(dest_id, id, exec=nil, p = 0)
		@dest_id = dest_id
		@name = ''
    @data_deps = Array.new
    @priority = p
    @execution_code = exec
    @output_data = nil
    @id = id
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

  def delete_task(id)
    Misc::remove_data(id)
    nil
  end

  def delete_original_task(id)
    Misc::remove_data_src(id)
    nil 
  end

  def serialize()
    "Task #{@id}"
  end

  def self.new_deserialize(str)
    str = str.split ' '
    unless(str.shift.eql? 'Task')
      puts "wrong deserialization".red
      return nil
    end
   	Misc::restore_task(str.shift).clone
  end
end
