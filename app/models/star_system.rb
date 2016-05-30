class StarSystem < ActiveRecord::Base
	ALPHA = 1
	BETA = 2
	GAMMA = 3
	DELTA = 4

	QUADS = [ALPHA, BETA, GAMMA, DELTA]

	QUAD_NAMES = {'Alpha' => 1, 'Beta' => 2, 'Gamma' => 3, 'Delta' => 4}
  	QUAD_NUMBERS = {1 => 'Alpha', 2 => 'Beta', 3 => 'Gamma', 4 => 'Delta'}

	MIN_RING = 1
	MAX_RING = 15

	belongs_to :periphery
	validates :name, presence: true
	belongs_to :affiliation
	
	has_many :celestial_bodies, dependent: :destroy
	has_many :bases, dependent: :nullify, class_name: 'Base'
	has_many :stargates, dependent: :destroy 
	has_many :stargate_routes, through: :stargates
	has_many :wormholes, dependent: :destroy

	after_destroy :destroy_jump_links
	after_destroy :destroy_paths

	def celestial_bodies
		@celestial_bodies ||= CelestialBody.where(:star_system_id => self.id).order('ring ASC, quad ASC')
	end

	def distance_multiplier(to_system)
		self.periphery.distance(to_system.periphery)
	 end

	def destroy_jump_links
		JumpLink.star_system(self).destroy_all
	end

	def destroy_paths
		Path.star_system(self).destroy_all
	end

	def to_s
		"#{self.name} (#{self.id})"
	end

	def government
		@government ||= (self.affiliation ? self.affiliation.long_name  : "Darkspace")
	end

	def populated_worlds
		@populated_worlds ||= self.celestial_bodies.select{|cbody| cbody.populated? }
	end

	def hazards
		@hazards ||= self.celestial_bodies.select{|cbody| cbody.hazard?}
	end

	def starbases(exclude_affiliation=nil)
		@starbases ||= (!exclude_affiliation.nil? ? Base.where(["starbase = 1 AND star_system_id = ? AND affiliation_id <> ? ", self.id, exclude_affiliation.id]) : Base.where({:starbase => true, :star_system_id => self.id}))
	end

	def public_markets
		@public_markets ||= starbases.select{|sb| sb.public_market? }.sort{|a,b| b.average_profit_of_starting_routes <=> a.average_profit_of_starting_routes}
	end

	def unique_trade_goods
		@unique_trade_goods || Item.sellable_goods.select{|item| item.star_system == self}.sort{|a,b| b.best_profit <=> a.best_profit }
	end

	def market_buys
		@market_buys ||= MarketBuy.where(["market_datum_id = ? AND starbase_id IN (?)", MarketDatum.today.id, self.starbases])
	end

	def market_sells
		@market_sells ||= MarketSell.where(["market_datum_id = ? AND starbase_id IN (?)", MarketDatum.today.id, self.starbases])
	end

	def best_buys(exclude_affiliation=nil)
		return @best_buys if @best_buys
		@best_buys = []
		market_buys.each do |mb|
		  best_buyer = mb.item.best_buyer
		  @best_buys << mb.item if best_buyer && best_buyer.starbase.star_system == self && (exclude_affiliation.nil? || exclude_affiliation != best_buyer.starbase.affiliation)
		end
		@best_buys = @best_buys.uniq{|i| i.id}
		@best_buys
	end

	def best_sells(exclude_affiliation=nil)
		return @best_sells if @best_sells
		@best_sells = []
		market_sells.each do |ms|
		  best_seller = ms.item.best_seller
		  @best_sells << ms.item if best_seller && best_seller.starbase.star_system == self && (exclude_affiliation.nil? || exclude_affiliation != best_seller.starbase.affiliation)
		end
		@best_sells = @best_sells.uniq{|i| i.id}
		@best_sells
	end

	def trade_routes(exclude_affiliation=nil)
		@trade_routes ||= TradeRoute.where(["from_id IN (?) OR to_id IN (?)",starbases(exclude_affiliation),starbases(exclude_affiliation)])
	end

	def self.fetch_cbodies!
		Nexus.html_client.login
		StarSystem.all.each{|s| Rails.logger.info "Fetching cbodies for #{s}"; s.fetch_cbodies!; Rails.logger.info "Found #{s.celestial_bodies.count}"}
	end

	def jump_links
		@jump_links ||= JumpLink.where(:from_id => self.id).order('jumps ASC')
	end

	def jump_linked_systems
		@jump_linked_systems ||= jump_links.map{|jump_link| jump_link.to}
	end

	def stargates
		@stargate_links ||= Stargate.where({:star_system_id => self.id})
	end

	def stargate_linked_systems
		@stargate_linked_systems ||= self.stargate_routes.map{|stargate| stargate.to.star_system}
	end

	def wormhole_links
		@wormhole_links ||= Wormhole.where({:star_system_id => self.id})
	end

	def wormhole_linked_systems
		@wormhole_linked_systems ||= wormhole_links.map{|wormhole| wormhole.to}
	end

	def quickest_jump(to_system)
		JumpLink.quickest_jump(self, to_system)
	end

	def path_to(to_system)
		Path.find_quickest(self, to_system)
	end

	def time_to(to_system)
		return 0 if self == to_system
		p = path_to(to_system)
		p.nil? ? 10000 : p.tu_cost
	end

	def nearest_affiliation_bases_from_system(affiliation)
		list = affiliation.starbases.to_a.select{|s| s.time_from_system(self) < 1000}
		list.sort {|a, b|a.time_from_system(self) <=> b.time_from_system(self)}
	end

	def find_nearest_affiliation_base_from_system(affiliation)
		list = nearest_affiliation_bases_from_system(affiliation)
		list.size > 0 ? list.first : nil
	end

	def fetch_cbodies!(fetch_cbody_data=false)
		response_code, doc = Nexus.html_client.get('game','system',self.id)
		return unless response_code == 200 && doc
		values = {}
		name_and_id = nil
		name = nil
		cbody_id = nil
		cbody_type = nil
		quad = nil
		ring = nil
		doc.xpath('//td[@class="cbody_text"]').each do |n|
		  unless (text = n.content.strip).blank?
		    # puts text
		    if name_and_id
		      if cbody_type
		        if quad
		          ring = text
		          values[cbody_id] = {:name => name, :cbody_type => cbody_type, :quad => quad, :ring => ring} if cbody_type # valid cbody
		          name_and_id = nil
		          name = nil
		          cbody_id = nil
		          cbody_type = nil
		          quad = nil
		          ring = nil
		        else
		          quad = text
		        end
		      elsif CelestialBody::CBODY_TYPES.include?(text)
		        cbody_type = text
		      else
		        cbody_type = nil
		      end
		    else
		      anchors = n.xpath('.//a')
		      a = anchors.size > 0 && anchors.first
		      if a && a['href'].include?('cbody')
		        name_and_id = text.split("(")
		        name = name_and_id[0].gsub('- ','').strip
		        cbody_id = name_and_id[1].gsub(')','')
		      end
		    end
		  end
		end
		values.each do |cbody_id, cbody_values|
		  cbody = CelestialBody.cbody(self.id, cbody_id)
		  cbody.name = cbody_values[:name]
		  cbody.cbody_type = cbody_values[:cbody_type]
		  cbody.quad = QUAD_NAMES[cbody_values[:quad]]
		  cbody.ring = cbody_values[:ring]
		  cbody.save!
		  if cbody.unknown? && fetch_cbody_data
		    unless cbody.fetch_cbody_data!
		      Nexus.html_client.login
		    end
		  end
		end
		values.size
	end
end
