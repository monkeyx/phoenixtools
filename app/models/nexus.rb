class Nexus < ActiveRecord::Base
	validates :nexus_user, presence: true
	validates :nexus_password, presence: true
	validates :affiliation_id, numericality: {only_integer: true}
	# setup_complete
	# updating_market
	# updating_turns
	# updating_items
	# updating_jump_map
	# updating_cbodies
	# core_fetched_at
	# market_fetched_at
	# turns_fetched_at
	# items_fetched_at
	# jump_map_fetched_at
	# cbodies_fetched_at
	# setup_notice
	# setup_error
	# update_notice
	# update_error
	validates :user_id, numericality: {only_integer: true}
	validates :xml_code, presence: true

	after_save :reset_clients

	def self.config
		Nexus.first
	end
	
	def self.html_client
		if config
			config.html_client 
		end
	end

	def self.xml_client
		if config
			config.xml_client 
		end
	end

	def html_client
		@html_client ||= NexusHtmlClient.new(self.nexus_user, self.nexus_password)
	end

	def xml_client
		@xml_client ||= NexusXMLClient.new(self.user_id, self.xml_code) 
	end

	def affiliation
		Affiliation.find_by_id(self.affiliation_id)
	end

	def doing_setup?
		!self.setup_complete?
	end

	def reset_clients
		@html_client = nil
		@xml_client = nil
	end

	def reset_update_flags!
		self.updating_market = false
		self.updating_turns = false
		self.updating_items = false
		self.updating_jump_map = false
		self.updating_cbodies = false
		self.update_notice = ''
		self.update_error = ''
		save!
	end

	def schedule_setup!
		update_attributes!(:setup_complete => false, :setup_notice => "Starting setup")
		LOG.info "Starting setup"
		setup!
	end

	def schedule_daily_update!(no_bases=false)
		update_attributes!(:updating_market => true)
		update_attributes!(:updating_items => true)
		update_items!
		unless no_bases
			update_attributes!(:updating_turns => true)
			update_turns!
		end
		update_market!
	end

	handle_asynchronously :schedule_daily_update!

	def schedule_full_update!
		update_attributes!(:updating_jump_map => true)
		update_jump_map!
		update_attributes!(:updating_cbodies => true)
		update_cbodies!
		update_attributes!(:updating_turns => true)
		update_turns!
		schedule_daily_update!(true)
	end

	handle_asynchronously :schedule_full_update!

	def daily_update_in_progress
		self.updating_market || self.updating_items || self.updating_turns
	end

	def full_update_in_progress
		daily_update_in_progress || self.updating_jump_map || self.updating_cbodies
	end

	def setup_known_stargates_and_wormholes!
		# STARGATES
		update_attributes!(:setup_notice => "Adding known stargates")
		Stargate.destroy_all
		StargateRoute.destroy_all
		LOG.info "Adding known stargates"
		Stargate.link_systems!(61,103, 5069, 1600)
		Stargate.link_systems!(103,186, 1600, 564)
		Stargate.link_systems!(103,121, 1600, 8434)
		Stargate.link_systems!(103,163, 1600, 3186)
		Stargate.link_systems!(103,23, 1600, 1253)
		Stargate.link_systems!(23,186, 1253, 564)
		Stargate.link_systems!(163,186, 3186, 564)
		Stargate.link_systems!(121,127, 8434, 4962)
		Stargate.link_systems!(161,103, 7230, 1600)
		Stargate.link_systems!(163,161, 3186, 7230)
		Stargate.link_systems!(121,182, 8434, 5114)
		Stargate.link_systems!(66,182, 5114, 8434)

		# WORMHOLES
		update_attributes!(:setup_notice => "Adding known wormholes")
		LOG.info "Adding known wormholes"
		Wormhole.destroy_all
		Wormhole.link_systems!(99,41,2231,565)
		Wormhole.link_systems!(6,9,3318,7637)
		Wormhole.link_systems!(17,104,0,8422)
		Wormhole.link_systems!(10,11,4562,2197)
		Wormhole.link_systems!(198,146,9890,3102)
		Wormhole.link_systems!(29,79,3236,6863)
		Wormhole.link_systems!(55,209,6735,2324)
	end

	def setup!
		xml = Nexus.xml_client
		xml.fetch_info!
		xml.fetch_positions!
		Base.link_outposts_to_hub!
		html = Nexus.html_client
		html.login
		update_attributes!(:setup_notice => "Fetching affiliation attributes")
		LOG.info "Fetching affiliation attributes"
		Affiliation.all.each{|a| a.fetch_affiliation_attributes! }
		JumpLink.destroy_all
		Periphery.all.each do |p| 
			html = Nexus.html_client
			html.login
			Nexus.config.update_attributes!(:setup_notice => "Fetching #{p} jump map")
			LOG.info "Fetching #{p} jump map"
			html.get_jump_map(p.id)
		end
		update_attributes!(:setup_notice => "Extrapolating jump links")
		LOG.info "Extrapolating jump links"
		JumpLink.extrapolate_until_no_more!
		setup_known_stargates_and_wormholes!
		update_attributes!(:setup_notice => "Generating paths")
		LOG.info "Generating paths"
		Path.generate!
		update_attributes!(:setup_notice => "Setup complete", :setup_complete => true, :core_fetched_at => Time.now, :jump_map_fetched_at => Time.now)
		LOG.info "Setup complete"
	end

	handle_asynchronously :setup!


	def update_market!
		update_attributes!(:update_notice => "Fetching market data")
		LOG.info "Fetching market data"
		MarketXml.fetch!
		update_attributes!(:update_notice => "Generating trade routes") 
		LOG.info "Generating trade routes"
		TradeRoute.generate!
		update_attributes!(:update_notice => "Trade routes generated", :updating_market => false, :market_fetched_at => Time.now)
		LOG.info "Trade routes generated"
	end

	def update_items!
		update_attributes!(:update_notice => "Fetching item data")
		LOG.info "Fetching item data"
		Item.fetch_missing!
		update_attributes!(:update_notice => "Item data fetched", :updating_items => false, :items_fetched_at => Time.now)
		LOG.info "Item data fetched"
	end

	def update_cbodies!
		update_attributes!(:update_notice => "Fetching celestial body data")
		LOG.info "Fetching celestial body data"
		StarSystem.fetch_cbodies!
		update_attributes!(:update_notice => "Celestial bodies mapped", :updating_cbodies => false, :cbodies_fetched_at => Time.now)
		LOG.info "Celestial bodies mapped"
	end

	def update_jump_map!
		JumpLink.destroy_all
		Periphery.all.each do |p| 
			html = Nexus.html_client
			html.login
			Nexus.config.update_attributes!(:update_notice => "Fetching #{p} jump map")
			LOG.info "Fetching #{p} jump map"
			html.get_jump_map(p.id)
		end
		update_attributes!(:update_notice => "Extrapolating jump links") 
		LOG.info "Extrapolating jump links"
		JumpLink.extrapolate_until_no_more!
		update_attributes!(:update_notice => "Generating paths") 
		LOG.info "Generating paths"
		Path.generate!
		update_attributes!(:update_notice => "Jump map up to date", :updating_jump_map => false, :jump_map_fetched_at => Time.now)
		LOG.info "Jump map up to date"
	end

	def update_turns!
		Position.destroy_all
		Base.destroy_all
		xml = Nexus.xml_client
		xml.fetch_positions!
		Base.link_outposts_to_hub!
		client = Nexus.html_client
		client.login 
		update_attributes!(:update_notice => "Fetching turns for bases")
		LOG.info "Fetching turns for bases"
		Position.bases.each{|p| p.base.fetch_turn!}
		update_attributes!(:update_notice => "Base turns fetched", :updating_turns => false, :turns_fetched_at => Time.now)
		LOG.info "Base turns fetched"
	end

	def update_paths_and_trade_routes!
		update_attributes!(:update_notice => "Generating paths") 
		LOG.info "Generating paths"
		Path.generate!
		update_attributes!(:update_notice => "Fetching market data")
		LOG.info "Fetching market data"
		MarketXml.fetch!
		update_attributes!(:update_notice => "Generating trade routes") 
		LOG.info "Generating trade routes"
		TradeRoute.generate!
	end
end
