class MarketBuy < ActiveRecord::Base
	belongs_to :item
	belongs_to :base
	validates :quantity, numericality: {only_integer: true}
	validates :price, numericality: true

	def to_s
		"#{quantity} x #{item} @ #{self.base}"
	end
end
