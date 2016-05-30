class BaseResource < ActiveRecord::Base
	belongs_to :item
	belongs_to :base
	validates :ore_mines, numericality: {only_integer: true}
	validates :resource_complexes, numericality: {only_integer: true}
	validates :resource_drop, numericality: {only_integer: true}
	validates :resource_id, numericality: {only_integer: true}
	validates :resource_size, numericality: {only_integer: true}
	validates :resource_yield, numericality: true

	scope :min_week_yields, ->(weeks) { where(["resource_size >= (resource_yield * resource_drop * ?)", weeks])}

	def to_s
		"#{self.item} \##{self.resource_id}"
	end

	def complexes
		if self.ore_mines > self.resource_complexes
			self.ore_mines
		else
			self.resource_complexes
		end
	end

	def current_output
		return @current_output if @current_output
		@current_output = 0.0
		return @current_output.to_i unless complexes
		@current_output = complex_output(complexes)
	end

	def next_complex_output
		(complexes ? complex_output(complexes + 1) - current_output : complex_output(1)).to_i
	end

	def max_complexes
		@max_complexes ||= (self.resource_drop * 10) - 1
	end

	def overexploited?
		complexes && complexes > max_complexes
	end

	def underexploited?
		complexes.nil? || (complexes < (max_complexes / 2))
	end

	def css_class
		if overexploited?
		  "text-warning"
		elsif underexploited?
		  "text-success"
		else
		  ""
		end
	end

	private
	def complex_output(number_of_complexes)
		output = 0.0
		output_modifier = 1.0
		n = 0
		while n < number_of_complexes do
		  diff = (number_of_complexes - n)
		  x = self.resource_drop
		  x = diff if x > diff
		  output += (self.resource_yield * output_modifier * x)
		  n += x
		  output_modifier -= 0.1
		  output_modifier = 0 unless output_modifier > 0
		end
		output = self.resource_size if self.resource_size && self.resource_size != -999 && self.resource_size < output
		output.to_i
	end
end
