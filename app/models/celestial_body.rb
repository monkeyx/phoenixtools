class CelestialBody < ActiveRecord::Base
	PLANET = 'Planet'
	GAS_GIANT = 'Gas Giant'
	MOON = 'Moon'
	NEBULA = 'Nebula'
	ASTEROID = 'Asteroid'
	ASTEROID_BELT = 'Asteroid Belt'
	WORMHOLE = 'Wormhole'
	STARGATE = 'Stargate'

	ATTRIBUTE_SEARCH_OPERATORS = ['=','>','<','>=','<=','<>','LIKE','NOT LIKE']

	CBODY_TYPES = [PLANET, GAS_GIANT, MOON, NEBULA, ASTEROID, ASTEROID_BELT, WORMHOLE, STARGATE]
	HAZARDS = [NEBULA, ASTEROID_BELT]

	has_many :bases, dependent: :nullify, class_name: 'Base'
	belongs_to :star_system
	validates :cbody_id, numericality: {only_integer: true}
	validates :cbody_type, inclusion: {in: CBODY_TYPES}, unless: "cbody_type.blank?"
	validates :ring, numericality: {only_integer: true, min: StarSystem::MIN_RING, max: StarSystem::MAX_RING}
	validates :quad, inclusion: {in: StarSystem::QUADS}, unless: "quad.nil? || quad == 0"
	validates :width, numericality: {only_integer: true}
	validates :height, numericality: {only_integer: true}
	has_many :celestial_body_attributes, dependent: :destroy
	has_many :sectors, dependent: :destroy
	has_many :wormholes, dependent: :destroy
	has_many :stargates, dependent: :destroy

	scope :star_system, ->(star_system) { where(:star_system_id => star_system.id )}
	scope :planets_only, -> {where(:cbody_type => PLANET)}
	scope :planets_or_moons_only, -> {where (["cbody_type IN (?)",[PLANET,MOON]]) }
	scope :gas_giants_only, -> {where(:cbody_type => GAS_GIANT)}

	def self.cbody(star_system_id, cbody_id)
		cb = where(star_system_id: star_system_id, cbody_id: cbody_id).first
		cb ||= create(star_system_id: star_system_id, cbody_id: cbody_id)
		cb
	end

	def to_s
		"#{self.name} (#{self.cbody_id})"
	end

	def terrain_types
		return @terrain_types if @terrain_types
		@terrain_types = {}
		self.sectors.each do |sq|
			terrain = @terrain_types[sq.terrain]
			terrain = 0 unless terrain
			terrain += 1
			@terrain_types[sq.terrain] = terrain
		end
		@terrain_types
	end

	def hazard?
		@hazard ||= HAZARDS.include?(self.cbody_type)
	end

	def breathable?
		@breathable ||= !get_cbody_attribute_value('Starbases can be open (no domes required)').nil?
	end

	def populated?
		return @populated if @populated
		v = get_cbody_attribute_value('Starbases require domes') || get_cbody_attribute_value('Starbases can be open (no domes required)')
		@populated = !v.nil? && v.include?('sentient')
	end

	def unknown?
		self.celestial_body_attributes.empty?
	end

	def quad_name
		@quad_name ||= StarSystem::QUAD_NUMBERS[self.quad]
	end

	def fetch_cbody_data!
		fail_count = 0
		while fail_count < 3 do
			if fail_count > 0
				Nexus.html_client.login
			end
			code, doc = Nexus.html_client.get('game', 'cbody',self.cbody_id,self.star_system_id)
			unless code == 200
				fail_count += 1
			else
				highest_x = 0
				highest_y = 0
				doc.xpath("//td[@title]").each do |td|
					#puts "TD = #{td['title']}"
			  		if td['title'].include?('(')
			    		terrain, x, y = parse_terrain_alt(td['title'])
			   	 		highest_x = x if x > highest_x
		    			highest_y = y if y > highest_y
			    		sq = Sector.where(celestial_body_id: self.id, x: x, y: y).first
			    		sq ||= Sector.create(celestial_body_id: self.id, x: x, y: y)
			    		sq.update_attributes!(:terrain => terrain)
			  		end
				end
				update_attributes!(:height => highest_y, :width => highest_x)
				values = {}
				key = nil
				doc.xpath('//td[@class="data_field"]').each do |n|
			  		if key
			    		values[key] = n.content.strip
			    		key = nil
			  		else
			    		key = n.content.strip
			    		key.slice!(key.length - 1) if key[-1, 1] == ':'
			  		end
				end
				if values.empty?
			  		fail_count += 1
				else
			  		values.each {|key,val|set_cbody_attribute_value!(key,val)}
			  		Rails.logger.info "Fetched data and map for #{self}"
			  		return self
				end
			end
		end
		nil
	end

	def map_square(x,y)
		Sector.where(celestial_body_id: self.id, x: x, y: y).first
	end

	def gpi_orders(number_of_ships)
		return unless self.height && self.width
		return unless number_of_ships && number_of_ships > 0
		ships = []
		total_sectors = self.width * self.height
		sectors_per_ship = (total_sectors / number_of_ships).to_i
		spare_sectors = total_sectors % sectors_per_ship

		current_row = 1
		current_col = 1
		(1..number_of_ships).each do |i|
		  ships[(i-1)] = []
		  sector_count = 0
		  while sector_count < sectors_per_ship && current_row <= self.height do
		    cols_to_gpi = (sectors_per_ship - sector_count)
		    end_x = current_col + cols_to_gpi
		    if end_x > self.width
		      end_x = self.width
		      cols_to_gpi = self.width - current_col
		    end
		    ships[(i-1)] << PhoenixOrder.gpi_row(current_row, current_col, end_x)
		    if end_x == self.width
		      current_row += 1
		      current_col = 1
		    else
		      current_col = end_x + 1
		    end
		    sector_count += cols_to_gpi
		  end
		end

		if spare_sectors > 0 && current_row <= self.height && current_col < self.width
		  ships.last << PhoenixOrder.gpi_row(self.height, (self.width - spare_sectors), self.width)
		end
		ships
	end

	def self.filter_by_terrain(terrain_types, list=all)
		return list if terrain_types.empty?
		terrain_types.each do |terrain|
			return list if list.empty?
			list = find_by_sql(["SELECT DISTINCT celestial_bodies.* FROM celestial_bodies, sectors WHERE sectors.celestial_body_id = celestial_bodies.id AND terrain = ? AND celestial_bodies.id IN (?)", terrain,list])
		end
		list
	end

	def self.filter_by_attribute(attributes, list=all)
		return list if attributes.empty?
		attributes.each do |attr_params|
			return list if list.empty?
			unless attr_params[:key].blank? 
				op = attr_params[:op].strip
				if op == '='
				  value_syntax = 'cast(celestial_body_attributes.attr_value as float)  = ?'
				elsif op == '<'
					value_syntax = 'cast(celestial_body_attributes.attr_value as float) < ?'
				elsif op == '>='
					value_syntax = 'cast(celestial_body_attributes.attr_value as float) >= ?'
				elsif op == '>'
					value_syntax = 'cast(celestial_body_attributes.attr_value as float) > ?'
				elsif op == '<='
					value_syntax = 'cast(celestial_body_attributes.attr_value as float) <= ?'
				elsif op == 'LIKE'
				  value_syntax = "(celestial_body_attributes.attr_value = ? OR celestial_body_attributes.attr_value LIKE '%#{attr_params[:value]}%')"
				elsif op == 'NOT LIKE'
				  value_syntax = "(celestial_body_attributes.attr_value <> ? AND celestial_body_attributes.attr_value NOT LIKE '%#{attr_params[:value]}%')"
				else
				  value_syntax = "celestial_body_attributes.attr_value #{op} CONVERT(?,DECIMAL)"
				end
				list = find_by_sql(["SELECT DISTINCT celestial_bodies.* FROM celestial_bodies, celestial_body_attributes WHERE celestial_body_attributes.celestial_body_id = celestial_bodies.id AND celestial_body_attributes.attr_key = ? AND #{value_syntax} AND celestial_bodies.id IN (?)",attr_params[:key],attr_params[:value],list.map{|c| c.id}])
			end
		end
		list
	end

	def self.fetch_all_data!(skip_mapped=true)
		unless skip_mapped
			list = all
		else
			list = all.select{|cb| cb.celestial_body_attributes.empty?}
		end
		list.each{|cb| Rails.logger.info "Fetching data for #{cb} in #{cb.star_system}"; cb.fetch_cbody_data!; Rails.logger.info "Found #{cb.terrain_types.keys.size} terrain types"}
	end

	def get_cbody_attribute_value(key)
	    attr = CelestialBodyAttribute.where({:celestial_body_id => self.id, :attr_key => key}).first
	    attr ? attr.attr_value : nil
	  end

	  def set_cbody_attribute_value!(key,val)
	  	attr = CelestialBodyAttribute.where(celestial_body_id: self.id, attr_key: key).first
	    attr ||= CelestialBodyAttribute.create(celestial_body_id: self.id, attr_key: key)
	    attr.attr_value = format_cbody_attribute_val(key, val)
	    attr.save!
	    self
	  end

	  def clear_cbody_attributes!
	    self.cbody_attributes.destroy_all
	    self
	  end

	private
	def parse_terrain_alt(alt)
		# puts alt
		parts = alt.split('(')
		name = parts[0].strip
		parts2 = parts[1].split(',')
		x = parts2[0].strip.to_i
		y = parts2[1].gsub(')','').strip.to_i
		return name,x,y
	end

	def format_cbody_attribute_val(key, val)
		case key
		when 'Gravity rating'
			return val ? val[0, val.length - 1] : '0'
		when 'Temperature'
			return val ? val : '0'
		when 'Optical Depth'
			return val ? val : '0'
		when 'Natural Shielding'
			return val ? val : '0'
		when 'Radiation'
			return val ? val : '0'
		when 'Tectonic Activity'
			return val ? val : '0'
		when 'TerraForming'
			return val ? val == 'None' ? '0' : val : '0'
		when 'Profile'
			return val ? val[0, val.length - 1] : '0'
		else
			return val
		end
	end
end
