class BaseItem < ActiveRecord::Base
	INVENTORY = "Inventory"
	RAW_MATERIALS = "Raw Materials"
	TRADE_ITEMS = "Trade Items"
	PERSONNEL = "Personnel"
  
	belongs_to :base
	belongs_to :item
	validates :quantity, numericality: {only_integer: true}
	validates :category, presence: true

	def to_s
		"#{self.quantity} x #{self.item}"
	end

	def total_mass
		(item.mass ? item.mass * quantity : nil)
	end
end
