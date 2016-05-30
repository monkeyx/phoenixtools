class Affiliation < ActiveRecord::Base
	# tag
	validates :name, presence: true

	has_many :affiliation_attributes, dependent: :destroy
	has_many :bases, dependent: :nullify, class_name: 'Base'
	has_many :star_systems, dependent: :nullify

	def to_s
		self.tag
	end

	def self.governments
	    all.select{|aff| aff.government? }
	  end

	  def free_trade_score
	    @free_trade_score ||= ((best_buys.size) + (best_sells.size * 20) + (trade_routes.size * 10))
	  end

	  def government_business_score
	    return nil unless government?
	    @government_business_score ||= (self.star_systems.sum{|ss| ss.trade_hub_score_excluding_government })
	  end

	  def bases
	    @bases ||= Base.where({:affiliation_id => self.id})
	  end

	  def description
	    @description ||= get_affiliation_attribute_value('Description')
	  end

	  def government?
	    !self.star_systems.empty?
	  end

	  def risks
	    return @risks if @risks
	    @risks = []
	    @risks << "Quick to change relations" unless get_affiliation_attribute_value("Relations change time") == "5 days"
	    @risks << "Sweeping change in relations possible" unless get_affiliation_attribute_value("Maximum single change in relations") == "1 level"
	    attack = get_affiliation_attribute_value("Can attack positions in")
	    unless attack.nil? || attack == "Can not carry enemy lists" || attack == "Nowhere"
	      @risks << "May attack in #{attack} without a formal declaration"
	    end
	    @risks << "May attack registered outposts" unless get_affiliation_attribute_value("Affiliation and allies can attack registered Outposts") == "No"
	    @risks << "May revoke registrations without notice" unless get_affiliation_attribute_value("Time to revoke outpost registration") == "10 days"
	    use_womd = get_affiliation_attribute_value("Can use WoMD")
	    @risks << "May use WoMDs #{use_womd.downcase}" unless use_womd.nil? || use_womd == "No where"
	    @risks
	  end

	  def legal_issues
	    return @legal_issues if @legal_issues
	    @legal_issues = []
	    @legal_issues << "May use Pirates" if get_affiliation_attribute_value("Can use pirate ships") == "Yes"
	    @legal_issues << "May use Mercenaries" if get_affiliation_attribute_value("Can use mercenary ships") == "Yes"
	    @legal_issues << "May use Privateers" if get_affiliation_attribute_value("Can use privateer ships") == "Yes"
	    @legal_issues << "May use Slaves" if get_affiliation_attribute_value("Can use slaves") == "Yes"
	    @legal_issues << "May use Indentured Workers" if get_affiliation_attribute_value("Can use indentured workers") == "Yes"
	    @legal_issues
	  end

	  def public_markets
	    @public_markets ||= starbases.select{|sb| sb.public_market? }.sort{|a,b| b.average_profit_of_starting_routes <=> a.average_profit_of_starting_routes}
	  end

	def relations
		return @relations if @relations
		attr = get_affiliation_attribute_value('Relations')
		return nil unless attr
		@relations = YAML.load(attr)
	end

	def allies
		@allies ||= relations_of('Allied')
	end

	def friends
		@friends ||= relations_of('Friendly')
	end

	def antagonistic
		@antagonistic ||= relations_of('Antagonistic')
	end

	def hostile
		@hostile ||= relations_of('Hostile')
	end

	def war
		@war ||= relations_of('War')
	end

	def market_buys
	    @market_buys ||= MarketBuy.where(["market_datum_id = ? AND starbase_id IN (?)", MarketDatum.today.id, self.starbases])
	  end

	  def market_sells
	    @market_sells ||= MarketSell.where(["market_datum_id = ? AND starbase_id IN (?)", MarketDatum.today.id, self.starbases])
	  end

	  def unique_trade_goods
	    @unique_trade_goods ||= market_sells.select{|ms| ms.item.sellable_good? }.map{|ms| ms.item}.uniq{|i| i.id}.sort{|a,b| b.best_profit <=> a.best_profit }
	  end

	  def best_buys
	    return @best_buys if @best_buys
	    @best_buys = []
	    market_buys.each do |mb|
	      best_buyer = mb.item.best_buyer
	      @best_buys << mb.item if best_buyer && best_buyer.starbase.affiliation == self
	    end
	    @best_buys = @best_buys.uniq{|i| i.id}
	    @best_buys
	  end

	  def best_sells
	    return @best_sells if @best_sells
	    @best_sells = []
	    market_sells.each do |ms|
	      best_seller = ms.item.best_seller
	      @best_sells << ms.item if best_seller && best_seller.starbase.affiliation == self
	    end
	    @best_sells = @best_sells.uniq{|i| i.id}
	    @best_sells
	  end

	  def trade_routes
	    @trade_routes ||= TradeRoute.where(["from_id IN (?) OR to_id IN (?)",starbases,starbases])
	  end

	  def get_affiliation_attribute_value(key)
	    attr = AffiliationAttribute.where({:affiliation_id => self.id, :attr_key => key}).first
	    return attr.attr_value if attr
	    nil
	  end

	  def set_affiliation_attribute_value!(key,val)
	    attr = AffiliationAttribute.where(affiliation_id: self.id, attr_key: key).first
	    attr ||= AffiliationAttribute.create(affiliation_id: self.id, attr_key: key)
	    attr.attr_value = val
	    attr.save!
	    self
	  end

	  def clear_affiliation_attributes!
	    self.affiliation_attributes.destroy_all
	    save!
	    self
	  end

	def fetch_affiliation_attributes!
		response_code, doc = Nexus.html_client.get('game','affs',self.id)
		return false unless response_code == 200 && doc
		self.affiliation_attributes.destroy_all
		values = {}
		key = nil
		doc.xpath('//td[@class="aff_text"]').each do |n|
		  # Rails.logger.info "N = #{n}"
		  if key
		    if key == 'Relations'
		      rels = {}
		      n.xpath('.//div[@class="rel"]').each do |o|
		        aff_tag = o.content.strip
		        relation = o['title']
		        aff = Affiliation.where(tag: aff_tag).first if aff_tag
		        rels[aff] = relation if aff
		      end
		      values[key] = rels.to_yaml
		    elsif key == 'Description'
		      s = n.content.strip
		      s = s.gsub(/[\.]\W\n/,"\n\n").gsub("\n",'')
		      values[key] = s
		    else
		      values[key] = n.content.strip
		    end
		    key = nil
		  elsif !n.content.strip.blank?
		    key = n.content.strip
		  end
		end
		if values.empty?
		  Nexus.html_client.login
		  return false
		else
		  values.each {|key,val|set_affiliation_attribute_value!(key,val)}
		end
		code = get_affiliation_attribute_value('Code')
		self.tag ||= code
		save
		Rails.logger.info "Fetched affiliation #{self}"
		self
	end

	private
	def relations_of(rel_type)
		if relations
			rels = []
			relations.each do |k,v|
				rel = parse_relation(v)[1]
				Rails.logger.info "#{self} -> #{k} = #{rel}"
				rels << k if rel == rel_type
			end
			return rels.uniq{|aff| aff.id}
		else
			return []
		end
	end

	def parse_relation(rel)
		rel = rel.split(' : ')
		return rel[0].strip, rel[1].strip
	end
end
