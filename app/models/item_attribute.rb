class ItemAttribute < ActiveRecord::Base
	belongs_to :item
	validates :attr_key, presence: true
	# attr_value

	def to_s
		"#{self.attr_key}=#{self.attr_value}"
	end

	def self.known_races
		@@known_races ||= ActiveRecord::Base.connection.execute("SELECT attr_value FROM item_attributes WHERE attr_key = 'Race' GROUP BY attr_value").map{|rs| rs[0]}
	end
end
