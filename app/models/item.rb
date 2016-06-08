class Item < ActiveRecord::Base
	INDUSTRIAL_MODULE_ID = 400
	MILITARY_MODULE_ID = 405
	BASIC_MODULE_ID = 410
	TRANSPORT_MODULE_ID = 415
	STRUCTURAL_MODULE_ID = 420

	RESEARCH_ITEM_TYPES = ['Blueprint', 'Technique', 'Principle']

	validates :name, presence: true
	validates :mass, numericality: {only_integer: true}
  # attributes_fetched
	belongs_to :item_type

	has_many :item_attributes, dependent: :destroy
	has_many :item_groups, dependent: :destroy
	has_many :market_buys, dependent: :destroy
	has_many :market_sells, dependent: :destroy
	has_many :mass_productions, dependent: :destroy
	has_many :trade_routes, dependent: :destroy
	has_many :base_resources, dependent: :destroy
  has_many :base_items, dependent: :destroy

  scope :missing_attributes, -> {where(:attributes_fetched => false)}

  def self.factory_cost(quantity=1)
    sm = find(STRUCTURAL_MODULE_ID)
    im = find(INDUSTRIAL_MODULE_ID)
    icmp = im.sell_price_data ? im.sell_price_data[0] : 50
    smp = sm.sell_price_data ? sm.sell_price_data[0] : 50
    factory_cost = (20 * icmp) + (5 * smp)
    (factory_cost * quantity).round(0).to_i
  end

	def to_s
		"#{self.name} (#{self.id})"
	end

  def self.fetch_missing!
    self.missing_attributes.each{|i| i.fetch_item_attributes!}
  end

	def self.fetch_if_new!(item_id, item_name, force_fetch=false)
		item = find_by_id(item_id)
		if item.nil?
		  item = new
		  item.id = item_id
		  item.name = item_name
		  item.save!
      item.fetch_item_attributes! if !item.attributes_fetched? || force_fetch
		end
		item
	end

	def self.inspect_all_related_items!
		Item.all.each do |item|
		  LOG.info "Inspecting #{item}"
		  item.blueprint
		  item.substitute_item
		  item.raw_materials
		end
	end

  def self.infrastructure
    all.to_a.select{|i| !i.infrastructure_type.blank? && i.infrastructure_type != 'None' }
  end

  def self.infrastructure_by_type(infrastructure_type)
    all.to_a.select{|i| !i.infrastructure_type.blank? && i.infrastructure_type == infrastructure_type }
  end

	def self.race_preferred_goods(race)
		sellable_goods.select{|i| i.race == race}
	end

	def self.periphery_goods(periphery)
		sellable_goods.select{|i| i.periphery == periphery}
	end

	def self.trade_goods
		all.to_a.select{|i| i.trade_good?}
	end

	def self.drugs
		all.to_a.select{|i| i.drug?}
	end

	def self.life_goods
		all.to_a.select{|i| i.life_good?}
	end

	def self.sellable_goods
		all.to_a.select{|i| i.sellable_good?}
	end

	def self.unknown
		all.select{|item| item.unknown?}
	end

	def self.profitable_but_no_trade_route
		all.select{|item| item.profitable_but_no_trade_route?}.sort{|a,b| b.best_profit <=> a.best_profit}
	end

	def self.producable
		Item.order('name ASC').select{|item| item.producable? && !item.unknown? && (item.blueprint.nil? || !item.blueprint.unknown?)}
	end

	def best_resource_for_item
		@best_resource_for_item ||= resources_for_item.first
	end

	def resources_for_item
		@resources_for_item ||= BaseResource.min_week_yields(5).where({:item_id => self.id}).to_a.select{|ir| ir.base}.uniq{|ir| ir.base_id}.sort{|a,b| b.next_complex_output <=> a.next_complex_output}[0..20]
	end

	def sub_type
		@sub_type ||= get_item_attr_value('Subtype')
	end

	def tech_manual
		@tech_manual ||= get_item_attr_value('Tech Manual')
	end

	def source_value
		return @source_value if @source_value
		attr = get_item_attr_value("Value at Source")
		return nil if attr.nil?
		i1 = attr.index('(')
		return nil unless i1
		@source_value = attr[0..i1].strip.to_f
	end

	def periphery
		return nil unless star_system
		@periphery ||= star_system.periphery.name if star_system.periphery
	end

	def star_system
		return @star_system if @star_system
		attr = get_item_attr_value("Origin System")
		return nil if attr.nil?
		i1 = attr.index('(')
		i2 = attr.index(')')
		return nil unless i1 && i2
		system_id = attr[(i1+1)..i2].to_i
		begin
		  @star_system = StarSystem.find_by_id(system_id)
		rescue
		  @star_system = nil
		end
		@star_system
	end

	def cbody
		return @cbody if @cbody
		return nil unless star_system
		attr = get_item_attr_value('Origin Celestial Body')
		return nil if attr.nil?
		i1 = attr.index('(')
		i2 = attr.index(')')
		return nil unless i1 && i2
		cbody_id = attr[(i1+1)..i2].to_i
		@cbody = CelestialBody.where(star_system_id: star_system.id, cbody_id: cbody_id).first
	end

	def race
		@race ||= get_item_attr_value("Race")
	end

	def item_type_attribute
		@item_type_attribute = get_item_attr_value('Type')
	end

  def infrastructure_type
    @infrastructure_type ||= (get_item_attr_value('Infrastructure Type'))
  end

	def sellable_good?
		trade_good? || life_good? || drug?
	end

	def trade_good?
		@is_trade_good ||= (item_type_attribute == 'Trade Good')
	end

	def drug?
		@is_drug ||= (item_type_attribute == 'Drug')
	end

	def life_good?
		@is_life ||= (item_type_attribute == 'Life')
	end

	def civilian?
		life_good? && (self.name == 'Hive Egg' || self.name.include?('Civilian'))
	end

	def local?(base)
		base && base.star_system && star_system && base.star_system == star_system
	end

	def distance_multiplier(base_system,base_cbody)
		return 0 if star_system.nil?
		if star_system == base_system
		  if cbody.nil? || cbody != base_cbody
		    return 3
		  else
		    return 1
		  end
		else
		  base_system.distance_multiplier(star_system)
		end
	end

	def local_price(base)
		return 0 unless base && base.trade_good_value_per_mu
		race_multiplier = (base.race.nil? || race.nil? || base.race == 'Sentient' || race == 'Sentient' || base.race != race) ? 1 : 2
		# LOG.info "RACE #{race_multiplier}"
		if trade_good?
		  planetary_multiplier = base.trade_good_value_per_mu
		elsif life_good?
		  planetary_multiplier = base.life_good_value_per_mu
		elsif drug?
		  planetary_multiplier = base.drug_value_per_mu
		else
		  planetary_multiplier = 0
		end
		# LOG.info "PLANET #{planetary_multiplier}"
		dm = distance_multiplier(base.star_system, base.celestial_body)
		# LOG.info "DISTANCE #{dm}"
		(dm * source_value * planetary_multiplier * race_multiplier).round(2)
	end

	def high_value_good?(starbase)
		price = local_price(starbase)
		return false if price == 0
		if trade_good?
		  price >= starbase.trade_good_high_value
		elsif life_good?
		  price >= starbase.life_good_high_value
		elsif drug?
		  price >= starbase.drug_high_value
		else
		  return false
		end
	end

	def low_value_good?(starbase)
		price = local_price(starbase)
		return false if price == 0
		if trade_good?
		  price <= starbase.trade_good_low_value
		elsif life_good?
		  price <= starbase.life_good_low_value
		elsif drug?
		  price <= starbase.drug_low_value
		else
		  return false
		end
	end

	def medium_value_good?(starbase)
		price = local_price(starbase)
		return false if price == 0
		!((high_value_good?(starbase) || low_value_good?(starbase)))
	end

	def market_bracket(starbase)
		return "H" if high_value_good?(starbase)
		return "L" if low_value_good?(starbase)
		"M"
	end

	def competitive_buy_price?(base)
		bb = best_buyer
		bs = best_seller
		rbp = recommended_buy_price(base)
		rbv = recommended_buy_volume(base)
		return false if (rbp <= 0 || rbv < 1) || 
		                (periphery == base.star_system.periphery) ||
                    (bs && bs.base == base) ||
                    (bb && bb.base == base)
    true
	end

	def recommended_buy_price(starbase)
    if high_value_good?(starbase)
      (local_price(starbase) * 0.6).round(2)
    elsif medium_value_good?(starbase)
      (local_price(starbase) * 0.8).round(2)
    else
      (local_price(starbase) * 0.7).round(2)
    end
	end

	def recommended_buy_volume(starbase)
    return 0 unless life_good? || trade_good?
		price = local_price(starbase)
		return 0 if price == 0
		stellars_per_category = (starbase.trade_good_max_income / 4)
    qty_for_item_per_week = (stellars_per_category / price).to_i
    if trade_good?
      if high_value_good?(starbase)
		    return 5000
      elsif medium_value_good?(starbase)
        return  25000
      else
        return 100000
      end
		elsif life_good?
		  return 10000
		end
	end

	def get_item_attr_value(key)
    attr = self.item_attributes.where(:attr_key => key).first
    return attr.attr_value if attr
    nil
  end

  def set_item_attr_value!(key,val)
    attr = ItemAttribute.where(item_id: self.id, attr_key: key).first
    attr ||= ItemAttribute.create(item_id: self.id, attr_key: key)
    attr.attr_value = val
    attr.save!
    self.mass = val.gsub('mus','').strip.to_i if key == 'Mus'
    self.name = val if key == 'Name'
    self.item_type = ItemType.where(name: val).first if key == 'Type'
    save!
    self
  end

  def clear_item_attributes!
    self.item_type = nil
    self.mass = nil
    self.item_attributes.destroy_all
    save!
    self
  end

  def fetch_item_attributes!
    response_code, doc = Nexus.html_client.get('game','items',self.id)
    return false unless response_code == 200 && doc
    self.item_attributes.destroy_all
    values = {}
    key = nil
    doc.xpath('//td[@class="data_field"]').each do |n|
      if key
        values[key] = n.content.strip
        key = nil
      else
        key = n.content.strip
      end
    end
    if values.empty?
      Nexus.html_client.login
      return false
    else
      values.each {|key,val|set_item_attr_value!(key,val)}
    end
    LOG.info "Fetched item #{self}"
    update_attributes(:attributes_fetched => true)
    self
  end

  def closest_best_buyer(star_system)
    return @nearest_buyer if @nearest_buyer
    MarketBuy.where({:item_id => self.id, :market_datum_id => MarketDatum.today.id}).order("price DESC").each do |mb|
      return (@nearest_buyer = mb) if mb.starbase.time_from_system(star_system) < TradeRoute::MAX_TUS && !mb.starbase.star_system.blacklist?
    end
    nil
  end

  def best_buyer
    return @best_buyer if @best_buyer
    MarketBuy.where(:item_id => self.id).order('price DESC').each do |mb|
      return (@best_buyer = mb) if mb.base.star_system
    end
    nil
  end

  def is_best_buyer?(base)
    return false unless best_buyer
    best_buyer.base == base
  end

  def best_seller
    return @best_seller if @best_seller
    MarketSell.where(:item_id => self.id).order('price ASC').each do |ms|
      return (@best_seller = ms) if ms.base.star_system
    end
    nil
  end

  def is_best_seller?(base)
    return false unless best_seller
    best_seller.base == base
  end

  def best_profit
    return @best_profit unless @best_profit.nil?
    return (@best_profit = 0) unless best_seller && best_buyer
    @best_profit = (best_buyer.price - best_seller.price).round(2)
  end
  
  def profitable_but_no_trade_route?
    best_buyer && best_seller && self.trade_routes.empty? && best_profit > 0
  end

  def middleman_buy_price
    return 0 unless best_seller && best_profit
    @middleman_buy_price ||= (best_seller.price + (best_profit * 0.4)).round(2)
  end

  def middleman_sell_price
    return 0 unless best_profit && middleman_buy_price > 0
    @middleman_sell_price ||= (middleman_buy_price + (best_profit * 0.2)).round(2)
  end

  def middleman_quantity
    return 0 unless best_seller && best_profit
    @middleman_quantity ||= best_seller.quantity
  end

  def middleman_orders
    return [] unless middleman_buy_price && middleman_buy_price > 0
    quantity = (50000 /  middleman_buy_price).round(0).to_i
    return [] unless middleman_sell_price > middleman_buy_price && middleman_buy_price < 25
    [
      PhoenixOrder.market_buy(self.id, quantity, middleman_buy_price,false,false,3),
      PhoenixOrder.market_sell(self.id, 50000,middleman_sell_price,false,false,3)
    ]
  end

  def substitute_item
    @substitute_item ||= get_attr_value_as_item('Substitute Item')
  end

  def substitute_ratio
    @substitute_ratio ||= get_attr_value_as_float('Substitute Ratio')
  end

  def tech_level
    @tech_level ||= get_attr_value_as_int('Tech level')
  end

  def production
    @production ||= get_attr_value_as_float('Production')
  end

  def production_limit
    @production_limit ||= get_attr_value_as_float('Production Limit')
  end

  def blueprint
    @blueprint ||= Item.find_by_id(get_attr_value_as_item('Blueprint'))
  end

  def raw_materials
    @raw_materials ||= get_attr_value_as_item_hash('Raw Materials')
  end

  def ammo
    @ammo ||= get_attr_value_as_item_hash('Ammo')
  end

  def producable?
    !RESEARCH_ITEM_TYPES.include?(self.item_type && self.item_type.name) && production && production > 0 && raw_materials
  end

  def researchable?
    RESEARCH_ITEM_TYPES.include?(self.item_type && self.item_type.name)
  end

  def estimated_production_cost
    return @estimated_production_cost if @estimated_production_cost
    return nil unless producable?
    @estimated_production_cost = (production / 50.0)
    raw_materials.keys.each do |item|
      quantity = raw_materials[item]
      if item.producable?
        @estimated_production_cost += (quantity * item.estimated_production_cost)
      elsif item.ore?
        case item.sub_type
          when 'Basic'
            @estimated_production_cost += (0.35 * quantity)
          when 'Uncommon'
            @estimated_production_cost += (3 * quantity)
          when 'Rare'
            @estimated_production_cost += (40 * quantity)
          else
            @estimated_production_cost += (2000 * quantity)
        end
      elsif item.sell_price_data
        @estimated_production_cost += (quantity * item.sell_price_data[0])
      elsif item.buy_price_data
        @estimated_production_cost += (quantity * item.buy_price_data[0])
      else
        @estimated_production_cost += 1000000 # arbitary because we can't find a price for this item
      end
    end
    @estimated_production_cost.round(2)
  end

  def rrp
    return @rrp if @rrp
    return nil unless estimated_production_cost
    bbp = best_buyer ? best_buyer.price : nil
    bsp = best_seller ? best_seller.price : nil
    isp = (estimated_production_cost * 2).round(0)
    if bsp
      @rrp = (bsp * 0.9).round(0)
    elsif bbp
      if isp < bbp
        @rrp = (bbp * 0.95).round(0)
      else 
        @rrp = (estimated_production_cost * 1.15).round(0)
      end
    else
      @rrp = isp
    end
    @rrp
  end

  def blueprint_cost
    return @blueprint_cost if @blueprint_cost
    return nil unless producable?
    return 0 unless blueprint
    if blueprint.best_seller
      @blueprint_cost = blueprint.best_seller.price
    else
      @blueprint_cost = 35000
    end
    @blueprint_cost
  end

  def factories_per_blueprint
    return @factories_per_blueprint if @factories_per_blueprint
    return nil unless producable? && blueprint && blueprint.production_limit
    @factories_per_blueprint = (blueprint.production_limit / 50).round(0).to_i
  end

  def initial_factories
    @initial_factories ||= (factories_per_blueprint ? (factories_per_blueprint > 50 ? 50 : factories_per_blueprint) : 50)
  end

  def items_per_blueprint
    return nil unless factories_per_blueprint
    items_produced(factories_per_blueprint)
  end

  def items_produced(factories=initial_factories)
    ((factories * 50) / production).to_i
  end

  def manufacturers_profit
    return nil unless estimated_production_cost
    @manufacturers_profit ||= rrp - estimated_production_cost
  end

  def profit_per_week(factories=initial_factories)
    manufacturers_profit ? items_produced(factories) * manufacturers_profit : nil
  end

  def investment_cost(factories=initial_factories)
    blueprint_cost ? blueprint_cost + Item.factory_cost(factories) : nil
  end

  def ROI(factories=initial_factories)
    profit_per_week(factories) && profit_per_week(factories) > 0 ? (investment_cost(factories) / profit_per_week(factories)).round(0).to_i : 100000
  end
  
  def uses?(item)
    rm = raw_materials
    return false unless rm && rm.size > 0
    !rm[item].nil? && rm[item] > 0
  end

  def used_by
    @used_by ||= Item.all.select{|item| item.uses?(self)}
  end

  def research_prequisites
    return @research_prequisites if @research_prequisites
    return nil unless researchable? && raw_materials && !raw_materials.empty?
    @research_prequisites = []
    raw_materials.keys.each do |item|
      @research_prequisites << item
    end
    @research_prequisites
  end

  def research_path
    return @research_path if @research_path
    return nil unless researchable?
    @research_path = []
    research_prequisites.each do |preq|
      @research_path = @research_path + preq.research_path unless preq.research_path.nil?
      @research_path << preq
    end unless research_prequisites.nil?
    @research_path
  end

  def unknown?
    self.reload
    self.item_attributes.empty?
  end

  def cargo?
    self.item_type && self.item_type.cargo?
  end

  def life?
    self.item_type && self.item_type.life?
  end

  def personnel?
    self.item_type && self.item_type.personnel?
  end

  def ore?
    self.item_type && self.item_type.ore?
  end

  def to_s
    "#{self.name} (#{self.id})"
  end

  def sale_volume
    @sale_volume ||= self.market_sells.sum{|mi| mi.quantity}
  end

  def buy_price_data
    return @buy_price_data if @buy_price_data
    size = self.market_buys.size
    return nil unless size > 0
    size = size.to_f
    price_sum = self.market_buys.to_a.sum{|mi| mi.price}.to_f
    mean = price_sum / size
    variance = self.market_buys.to_a.sum {|mi| diff = (mean - mi.price); diff * diff} / size
    std_deviation = Math.sqrt(variance)
    return (@buy_price_data = [mean.round(2), std_deviation.round(2)])
  end

  def buy_price_string
    return nil unless buy_price_data
    "$#{buy_price_data[0]} +- #{buy_price_data[1]}"
  end

  def sell_price_data
    return @sell_price_data if @sell_price_data
    size = self.market_sells.size
    return nil unless size > 0
    size = size.to_f
    price_sum = self.market_sells.to_a.sum{|mi| mi.price}.to_f
    mean = price_sum / size
    variance = self.market_sells.to_a.sum {|mi| diff = (mean - mi.price); diff * diff} / size
    std_deviation = Math.sqrt(variance)
    return (@sell_price_data = [mean.round(2), std_deviation.round(2)])
  end

  def sell_price_string
    return nil unless sell_price_data
    "$#{sell_price_data[0]} +- #{sell_price_data[1]}"
  end

  private
  def get_attr_value_as_item(key)
    attr = get_item_attr_value("item:#{key}")
    return Item.find_by_id(attr) if attr
    attr = get_item_attr_value(key)
    return nil unless attr
    ni = attr.index('(')
    nj = attr.index(')')
    item_name = attr[0..(ni-1)].strip
    item_id = attr[(ni+1)..nj].strip.to_i
    set_item_attr_value!("item:#{key}", item_id)
    i = Item.find_by_id(item_id)
    unless i
      i = Item.new(name: item_name)
      i.id = item_id
      i.save
    end
  end

  def get_attr_value_as_float(key)
    attr = get_item_attr_value(key)
    return nil unless attr
    attr.to_f
  end

  def get_attr_value_as_int(key)
    attr = get_item_attr_value(key)
    return nil unless attr
    attr.to_i
  end

  def load_item_hash(yaml_string)
#    LOG.info "YAML = #{yaml_string}"
    map = YAML.load(yaml_string)
    hash = {}
    map.each do |k,v|
      item = Item.find_by_id(k)
      unless item
        item = Item.new(name: v[:name])
        item.id = k 
        item.save
      end
      hash[item] = v[:quantity]
    end
    hash
  end

  def get_attr_value_as_item_hash(key)
    attr = get_item_attr_value("hash:#{key}")
    if attr
      return load_item_hash(attr)
    end
    attr = get_item_attr_value(key)
    return nil unless attr
    attr = attr.split(')')
    quantity_id_map = {}
    attr.each do |line|
      ni = line.index(' ')
      quantity = line[0..ni].strip.to_f
      nj = line.index('(')
      name = line[(ni+1)..(nj-1)].strip
      item_id = line[(nj+1)..(line.length - 1)].to_i
      quantity_id_map[item_id] = {:quantity => quantity, :name => name}
    end
    set_item_attr_value!("hash:#{key}", quantity_id_map.to_yaml)
    hash = {}
    quantity_id_map.keys.each do |k|
      item = Item.find_by_id(k)
      unless item
        item = Item.new(name: quantity_id_map[k][:name])
        item.id = k 
        item.save
      end
      hash[item] = quantity_id_map[k][:quantity]
    end
    hash
  end
end
