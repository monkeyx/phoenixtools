class CelestialBodyAttribute < ActiveRecord::Base
	belongs_to :celestial_body
	validates :attr_key, presence: true
	# attr_value

	def to_s
		"#{self.attr_key}=#{self.attr_value}"
	end
end
