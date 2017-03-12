class NexusXMLClient
	def initialize(user_id,xml_code)
		@user_id = user_id
		@xml_code = xml_code
	end

	def fetch_info!
		LOG.info "Fetching info data..."
		doc = doc('info_data')

		e_data_types = doc.xpath('//data_types')

		e_data_types.xpath('.//type').each do |e_data_type|
			if e_data_type['name'] == 'Items'
				Nexus.config.update_attributes!(:setup_notice => "Adding known items")
				LOG.info "Adding known items"
				parse_items!(e_data_type)
			elsif e_data_type['name'] == 'Systems'
				Nexus.config.update_attributes!(:setup_notice => "Adding known star systems")
				LOG.info "Adding known star systems"
				parse_star_systems!(e_data_type)
			elsif e_data_type['name'] == 'Affiliation'
				Nexus.config.update_attributes!(:setup_notice => "Adding known affilitions")
				LOG.info "Adding known affilitions"
				parse_affiliations!(e_data_type)
			elsif e_data_type['name'] == 'Item Type'
				Nexus.config.update_attributes!(:setup_notice => "Adding known item types")
				LOG.info "Adding known item types"
				parse_item_types!(e_data_type)
			end
		end

		LOG.info "Finished fetching info data"
	end

	def fetch_positions!
		LOG.info "Fetching positions data"
		Nexus.config.update_attributes!(:setup_notice => "Fetching owned positions", :update_notice => "Fetching owned positions")
		doc = doc('pos_list')
		puts doc

		e_positions = doc.xpath('.//positions')

		e_positions.xpath('.//position').each do |e_position|
			puts e_position
			parse_position!(e_position)
		end
	end

	private
	def parse_location!(p, loc_str)
		a = loc_str.split(' - ')
		loc = nil
		sys_loc = nil
		sys_name = nil
		if a.length > 2
			loc = a[0]
			sys_loc = a[1]
			sys_name = a[2]
		elsif a.length > 1
			loc = a[0]
			sys_name = a[1]
		else
			loc = a[0]
		end
		LOG.debug "LOC = #{loc} SYS_LOC = #{sys_loc} SYS_NAME = #{sys_name}"
		if sys_name
			sys_id = sys_name.split('(')[1].gsub(')','').to_i
			LOG.debug "SYS ID = #{sys_id}"
			p.star_system = StarSystem.find_by_id(sys_id)
		end
		if sys_loc && sys_loc.include?('Quadrant') && (sys_loc = sys_loc.gsub('Quadrant','').strip)
			quad, ring = sys_loc.split(' ')
			p.quad = StarSystem::QUAD_NAMES[quad]
			p.ring = ring
		end
		if loc
			if loc.include?('Landed') || loc.include?('Docked')
				p.landed = true
				if loc.include?('Landed')
					cbody_id = loc.split('(')[1].split(')')[0].to_i
					LOG.debug "CBODY = #{cbody_id}"
					p.celestial_body = CelestialBody.cbody(sys_id, cbody_id) if sys_id
				elsif loc.include?('Docked')
					base_id = loc.split('(')[1].split(')')[0].to_i if loc.split('(').length > 1
					LOG.debug "BASE ID = #{base_id}"
					b = Base.find_by_id(base_id)
					p.celestial_body = b.celestial_body if b
				end
			elsif loc.include?('Orbit')
				p.orbit = true
				cbody_id = loc.split('(')[1].split(')')[0].to_i
				LOG.debug "CBODY = #{cbody_id}"
				p.celestial_body = CelestialBody.cbody(sys_id, cbody_id) if sys_id
			end
		end
	end

	def parse_size!(p, size_str)
		size, size_type = size_str.split(' ')
		p.size = size.blank? ? 0 : size.to_i
		p.size_type = size_type
	end

	def parse_position!(e_position)
		p = Position.find_by_id(e_position['num'].to_i)
		p ||= Position.new
		p.name = e_position['name'].to_s
		p.position_class = e_position.xpath('.//class').first.content
		p.design = e_position.xpath('.//design').first.content
		p.id = e_position['num'].to_i
		parse_location!(p, e_position.xpath('.//loc_text').first.content)
		parse_size!(p, e_position.xpath('.//size').first.content)
		LOG.info "Added #{p}" if p.save!
	end

	def parse_items!(e_data_type)
		e_data_type.xpath('.//data').each do |e_data|
			unless Item.find_by_id(e_data['num'].to_i)
				i = Item.new(name: e_data['name'].to_s)
				i.id = e_data['num'].to_i
				LOG.info "Added #{i}" if i.save
			end
		end
	end

	def parse_star_systems!(e_data_type)
		e_data_type.xpath('.//data').each do |e_data|
			unless StarSystem.find_by_id(e_data['num'].to_i)
				i = StarSystem.new(name: e_data['name'].to_s)
				i.id = e_data['num'].to_i
				LOG.info "Added #{i}" if i.save
			end
		end
	end

	def parse_affiliations!(e_data_type)
		e_data_type.xpath('.//data').each do |e_data|
			unless Affiliation.find_by_id(e_data['num'].to_i)
				i = Affiliation.new(name: e_data['name'].to_s)
				i.id = e_data['num'].to_i
				LOG.info "Added #{i}" if i.save
			end
		end
	end
	
	def parse_item_types!(e_data_type)
		e_data_type.xpath('.//data').each do |e_data|
			unless ItemType.find_by_id(e_data['num'])
				i = ItemType.new(name: e_data['name'])
				i.id = e_data['num']
				LOG.info "Added #{i}" if i.save
			end
		end
	end

	def doc(data_type)
		Nokogiri::HTML(open(url(data_type)))
	end

	def url(data_type)
		"#{XML_BASE}?a=xml&uid=#{@user_id}&code=#{@xml_code}&sa=#{data_type}"
	end
end