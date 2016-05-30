class Position < ActiveRecord::Base
	BASE_CLASSES = ['Starbase','Outpost']

	include Turn
	validates :name, presence: true
	belongs_to :star_system
	belongs_to :celestial_body
	validates :quad, inclusion: {in: StarSystem::QUADS}, unless: "quad.nil? || quad == 0"
	validates :ring, numericality: {only_integer: true}, unless: "ring.nil?"
	# landed
	# orbit
	validates :size, numericality: {only_integer: true}, unless: "size.nil?"
	# size_type
	# design
	# position_class

	after_save :create_base

	scope :bases, -> {where(['position_class IN (?)', BASE_CLASSES])}
	scope :starbases, -> {where("position_class = 'Starbase'")}

	def to_s
		"#{self.name} (#{self.id})"
	end

	def base
		@base ||= Base.find_by_id(self.id) if base?
	end

	def base?
		BASE_CLASSES.include?(self.position_class)
	end

	def starbase?
		self.position_class == 'Starbase'
	end

	def outpost?
		self.position_class == 'Outpost'
	end

	def create_base
		base = Base.find_by_id(self.id)
		base ||= Base.new
		base.id = self.id
		base.name = self.name
		base.affiliation = Nexus.config.affiliation
		base.star_system = self.star_system
		base.celestial_body = self.celestial_body
		base.starbase = self.starbase?
		base.save!
	end
end
