class Stargate < ActiveRecord::Base
	belongs_to :star_system
	belongs_to :celestial_body
	has_many :path_points, dependent: :destroy
	has_many :stargate_routes, dependent: :destroy, foreign_key: "from_id"

	def self.link_systems!(a_id, b_id, cbody_a, cbody_b)
	    from = Stargate.where(star_system_id: a_id).first
	    from ||= Stargate.create(star_system_id: a_id)
	    to = Stargate.where(star_system_id: b_id).first
	    to ||= Stargate.create(star_system_id: b_id)
	    unless cba = CelestialBody.where(star_system_id: a_id, cbody_id: cbody_a).first
	    	cba = CelestialBody.create!(:star_system_id => a_id, :cbody_id => cbody_a, :name => 'Stargate', :cbody_type => 'Stargate') 
	    end
	    unless cbb = CelestialBody.where(star_system_id: b_id, cbody_id: cbody_b).first
	    	cbb = CelestialBody.create!(:star_system_id => b_id, :cbody_id => cbody_b, :name => 'Stargate', :cbody_type => 'Stargate') 
	    end
	    from.celestial_body = cba
	    from.save
	    to.celestial_body = cbb
	    to.save
	    from.add_link!(to)
	end

	def add_link!(to)
		StargateRoute.create(from: self, to: to)
		StargateRoute.create(from: to, to: self)
	end

	def to_s
		self.celestial_body.to_s
	end
end
