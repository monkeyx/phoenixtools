class StargateRoute < ActiveRecord::Base
	belongs_to :from, class_name: "Stargate"
	belongs_to :to, class_name: "Stargate"

	def to_s
		"#{self.from.star_system}->#{self.to.star_system}"
	end

	def star_system
		from_star_system
	end

	def from_star_system
		self.from.star_system
	end

	def to_star_system
		self.to.star_system
	end
	
	def known?
		self.from && self.to
	end
end
