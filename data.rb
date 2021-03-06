class Data_
	attr_reader :id, :data, :move_flag
	def initialize(id, data = nil, move_flag = true)
		@id = id
		@data = data
		@move_flag = move_flag
	end

  def to_s()
    "ID: #{id}; dest_id: #{Misc::get_dest_from_id(@id)}\n#{@data.to_s}"
  end

  def serialize()
  	data_ser = ''
  	data_ser = @data.serialize unless @data.nil?
    "Data #{id} #{@data.class.to_s} #{data_ser}"
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
    data = (Module.const_get(data_type)).new_deserialize(data_ser) unless data_type.eql? 'NilClass'
    obj = new(id, data, false)
    obj
  end
end