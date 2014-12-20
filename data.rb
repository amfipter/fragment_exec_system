class Data_
	attr_reader :id, :data
	def initialize(id, data = nil)
		@id = id
		@data = data
	end

  def to_s()
    "ID: #{id}; dest_id: #{Misc::get_dest_from_id(@id)}\n#{data.to_s}"
  end

  def serialize()
    "Data #{id} #{@data.class.to_s} #{@data.serialize}"
  end

  def self.new_deserialize(str)
    str = str.split ' '
    unless(str.shift.eql? "Data")
      puts "wrong deserialization".red
      return nil 
    end
    id = str.shift 
    data_type = str.shift
    data_ser = str.join ' '
    data = (Module.const_get(data_type)).new_deserialize(data_ser)
    obj = new(id, data)
    obj
  end
end