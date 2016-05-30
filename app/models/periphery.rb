class Periphery < ActiveRecord::Base
	validates :name, presence: true
	has_many :star_systems, dependent: :nullify
	has_many :periphery_distances, dependent: :destroy

	def add_distance!(other, distance)
		PeripheryDistance.create(periphery: self, to: other, trade_distance_modifier: distance)
	end

	def distance(other)
		return 8 unless other
		pd = PeripheryDistance.where(:periphery_id => self.id, to_id: other.id).first
		pd ? pd.trade_distance_modifier : 0
	end

	def to_s
		self.name
	end
end
