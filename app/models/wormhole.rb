class Wormhole < ActiveRecord::Base
	belongs_to :star_system
	belongs_to :to, class_name: "StarSystem"
	belongs_to :celestial_body
	has_many :path_points, dependent: :destroy

	def self.link_systems!(a_id, b_id, cbody_a, cbody_b)
	    return if Wormhole.exists?(star_system_id: a_id, to_id: b_id)
	    unless cba = CelestialBody.where(star_system_id: a_id, cbody_id: cbody_a).first
	    	cba = CelestialBody.create!(:star_system_id => a_id, :cbody_id => cbody_a, :name => 'Wormhole', :cbody_type => 'Wormhole') 
	    	cbody_a = cba.id
	    end if cbody_a > 0
	    unless cbb = CelestialBody.where(star_system_id: b_id, cbody_id: cbody_b).first
	    	cbb = CelestialBody.create!(:star_system_id => b_id, :cbody_id => cbody_b, :name => 'Wormhole', :cbody_type => 'Wormhole') 
	    	cbody_b = cbb.id
	    end if cbody_b > 0
	    Wormhole.create!(:star_system_id => a_id, :to_id => b_id, :celestial_body_id => cbody_a)
	    Wormhole.create!(:star_system_id => b_id, :to_id => a_id, :celestial_body_id => cbody_b)
	end

	def known?
		self.to && self.star_system
	end

	def to_s
		self.celestial_body.to_s
	end
end
