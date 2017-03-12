namespace :phoenixtools do
	task :reset => :environment do 
		Nexus.config.reset_update_flags!
	end

	task :turns => :environment do 
		MarketXml.fetch!
		TradeRoute.generate!
		Item.fetch_missing!
		xml = Nexus.xml_client
		xml.fetch_positions!
		Base.link_outposts_to_hub!
		client = Nexus.html_client
		client.login 
		Position.starbases.each{|p| p.base.fetch_turn!}
	end

	task :all_turns => :environment do 
		MarketXml.fetch!
		TradeRoute.generate!
		Item.fetch_missing!
		xml = Nexus.xml_client
		xml.fetch_positions!
		Base.link_outposts_to_hub!
		client = Nexus.html_client
		client.login 
		Position.bases.each{|p| p.base.fetch_turn!}
	end

	task :setup => :environment do 
		xml = Nexus.xml_client
		xml.fetch_info!
		xml.fetch_positions!
		Base.link_outposts_to_hub!
		html = Nexus.html_client
		html.login
		Nexus.config.update_attributes!(:setup_notice => "Fetching affiliation attributes")
		Affiliation.all.each{|a| a.fetch_affiliation_attributes! }
		JumpLink.destroy_all
		Periphery.all.each do |p| 
			html = Nexus.html_client
			html.login
			Nexus.config.update_attributes!(:setup_notice => "Fetching #{p} jump map")
			html.get_jump_map(p.id)
		end
		Nexus.config.update_attributes!(:setup_notice => "Extrapolating jump links")
		JumpLink.extrapolate_until_no_more!
		Nexus.config.setup_known_stargates_and_wormholes!
		Nexus.config.update_attributes!(:setup_notice => "Generating paths")
		Path.generate!
		Nexus.config.update_attributes!(:setup_notice => "Setup complete", :setup_complete => true, :core_fetched_at => Time.now, :jump_map_fetched_at => Time.now)
	end
end