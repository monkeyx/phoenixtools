class MassProduction < ActiveRecord::Base
	belongs_to :base
	belongs_to :item
	validates :factories, numericality: {only_integer: true}
	# status

	def to_s
		"#{factories} x #{item} @ #{self.base} (#{self.status})"
	end

	def self.production_report
		report = {}
		all.each do |mp|
			item_entry = report[mp.item]
			item_entry = 0 unless item_entry
			item_entry += mp.item_output
			report[mp.item] = item_entry
		end
		report.select{|k,v| v > 0}
	end

	def running?
		self.status == 'Running'
	end

	def production
		return @production if @production
		return nil unless self.factories && running?
		@production = 0
		factories_remaining = self.factories
		facts = factories_remaining > 10 ? 10 : factories_remaining
		@production += (45 * facts)
		factories_remaining -= facts
		return @production if factories_remaining < 1
		facts = factories_remaining > 10 ? 10 : factories_remaining
		@production += (50 * facts)
		factories_remaining -= facts
		return @production if factories_remaining < 1
		facts = factories_remaining > 20 ? 20 : factories_remaining
		@production += (55 * facts)
		factories_remaining -= facts
		return @production if factories_remaining < 1
		@production = @production + (factories_remaining * 50)
	end

	def item_output
		@item_output ||= (production && self.item.production ? (production / self.item.production).round(1) : 0)
	end

	def raw_materials
		return @raw_materials if @raw_materials
		return nil unless self.item.raw_materials
		@raw_materials = self.item.raw_materials.clone
		@raw_materials.keys.each do |item|
		@raw_materials[item] = (@raw_materials[item] * item_output).round(0).to_i
		end
		@raw_materials
	end
end
