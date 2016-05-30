class ItemType < ActiveRecord::Base
	TYPE_PERSONNEL = ['Troop','Pirate','Officer','Employee']
	TYPE_LIFE = ['Operative','Civilian','Prisoner','Trade Life','Plants'] + TYPE_PERSONNEL
	TYPE_ORE = ['Ore','Alloy']

	validates :name, presence: true

	has_many :items, dependent: :nullify

	def to_s
		self.name
	end

	def cargo?
		!(life? || ore?)
	end

	def life?
		TYPE_LIFE.include?(self.name)
	end

	def personnel?
		TYPE_PERSONNEL.include?(self.name)
	end

	def ore?
		TYPE_ORE.include?(self.name)
	end
end
