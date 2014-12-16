class Data_
	attr_reader :id, :data
	def initialize(id, data = nil)
		@id = id
		@data = data
	end

  def to_s()
    "#{id}\n#{data.to_s}"
  end
end