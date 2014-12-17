class Data_
	attr_reader :id, :data
	def initialize(id, data = nil)
		@id = id
		@data = data
	end

  def to_s()
    "ID: #{id}; dest_id: #{Misc::get_dest_from_id(@id)}\n#{data.to_s}"
  end
end