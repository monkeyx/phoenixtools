class Sector < ActiveRecord::Base
	belongs_to :celestial_body
	validates :x, numericality: {only_integer: true}
	validates :y, numericality: {only_integer: true}
	validates :terrain, presence: true

	def to_s
		"#{x},#{y} - #{self.terrain}"
	end

	def gif
		"http://phoenixbse.com/black/#{self.terrain.downcase}.gif"
	end
end
