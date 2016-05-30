class ItemGroup < ActiveRecord::Base
	belongs_to :base
	validates :name, presence: true
	validates :group_id, numericality: {only_integer: true}
	belongs_to :item
	validates :quantity, numericality: {only_integer: true}

	def to_s
		"#{self.name} (#{self.group_id})"
	end

	def total_mass
	    (item.mass ? item.mass * quantity : nil)
	end
end
