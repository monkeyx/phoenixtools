class PeripheryDistance < ActiveRecord::Base
	validates :trade_distance_modifier, numericality: {only_integer: true}
	belongs_to :periphery 
	belongs_to :to, class_name: 'Periphery'

	def to_s
		"#{self.periphery}->#{self.to} x#{self.trade_distance_modifier}"
	end
end
