class StargateRoute < ActiveRecord::Base
	belongs_to :from, class_name: "Stargate"
	belongs_to :to, class_name: "Stargate"

	def to_s
		"#{self.from.star_system}->#{self.to.star_system}"
	end

	def star_system
		self.from
	end
end
