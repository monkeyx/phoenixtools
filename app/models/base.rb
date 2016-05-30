class Base < ActiveRecord::Base
	MAXIMUM_WEEKS_TRADE_RESERVES = 26

	include Turn
	validates :name, presence: true
	belongs_to :affiliation
	belongs_to :star_system
	belongs_to :celestial_body
	validates :hiports, numericality: {only_integer: true}
	validates :patches, numericality: true
	validates :docks, numericality: {only_integer: true}
	validates :maintenance, numericality: {only_integer: true}
	validates :trade_good_value_per_mu, numericality: true
	validates :life_good_value_per_mu, numericality: true
	validates :drug_value_per_mu, numericality: true
	validates :trade_good_low_value, numericality: true
	validates :trade_good_high_value, numericality: true
	validates :life_good_low_value, numericality: true
	validates :life_good_high_value, numericality: true
	validates :drug_low_value, numericality: true
	validates :drug_high_value, numericality: true
	validates :trade_good_max_income, numericality: true
	validates :life_good_max_income, numericality: true
	validates :drug_max_income, numericality: true
	# race
	# blacklist
	# starbase
  belongs_to :hub, class_name: "Base"

	has_many :base_items, dependent: :destroy
	has_many :item_groups, dependent: :destroy
	has_many :market_buys, dependent: :destroy
	has_many :market_sells, dependent: :destroy
	has_many :mass_productions, dependent: :destroy
	has_many :base_resources, dependent: :destroy

	after_destroy :destroy_trade_routes

  scope :starbases, -> { where(:starbase => true )}
  scope :outposts, -> { where(:starbase => false )}
  scope :feeder, ->(base) { where(:hub_id => base.id )}
  scope :star_system, ->(star_system) { where(:star_system_id => star_system.id )}
  scope :has_star_system, -> { where("star_system_id <> 0 AND star_system_id IS NOT NULL")}
  scope :no_hub, -> {where("hub_id = 0 OR hub_id IS NULL")}

  def self.link_outposts_to_hub!
    Base.outposts.has_star_system.no_hub.each do |base|
      if base.star_system
        hub = Base.starbases.star_system(base.star_system).first
        base.update_attributes!(:hub_id => hub.id) if hub
      end
    end
  end

  def outposts
    Base.feeder(self)
  end

  def outpost?
    !self.starbase
  end

  def own_aff?
    Nexus.config.affiliation == self.affiliation
  end

	def destroy_trade_routes
		TradeRoute.base(self).destroy_all
	end

	def to_s
		"#{self.affiliation} #{self.name} (#{self.id})"
	end

	def after_load
		@worth_buying = {}
		@weekly_supply = {}
	end

	def public_market?
		self.market_buys.size > 0 || self.market_sells.size > 0
	end

	def planetary_market?
		!self.trade_good_value_per_mu.nil? || !self.life_good_value_per_mu.nil? || !self.drug_value_per_mu.nil?
	end

	def blacklist_toggle!
		self.blacklist = self.blacklist.nil? ? true : !self.blacklist
		save!
		self.blacklist
	end

	def resource_report
    return @resource_report if @resource_report
    @resource_report = {}
    resource_production.keys.each do |item|
      if resource_production[item] > 0
        item_entry = {:production => resource_production[item], :available => count_item(item), :consumption => 0, :css_class => '', :best_resource => best_resource_for_item(item)}
        @resource_report[item] = item_entry
      end
    end
    resource_consumption.keys.each do |item|
      if resource_consumption[item] > 0
        item_entry = @resource_report[item]
        item_entry = {:available => count_item(item), :css_class => '', :production => 0} unless item_entry
        item_entry[:consumption] = resource_consumption[item]
        item_entry[:weekly_burn] = (item_entry[:consumption] - item_entry[:production]).round(0).to_i
        if item_entry[:weekly_burn] > 0
          item_entry[:weeks_remaining] = (item_entry[:available] / item_entry[:weekly_burn]).round(0).to_i
          if item_entry[:weeks_remaining] < 26
            item_entry[:css_class] = 'text-warning'
          end
        else
          item_entry[:weeks_remaining] = 'Forever'
          item_entry[:css_class] = 'text-success'
        end
        item_entry[:best_resource] = best_resource_for_item(item) unless item_entry[:best_resource]
        @resource_report[item] = item_entry
      end
    end
    @resource_report
  end

  def resource_production(existing={})
    return @resource_production if @resource_production
    @resource_production = existing || {}
    self.base_resources.each do |ir|
      production = @resource_production[ir.item]
      production = 0 unless production
      production += ir.current_output
      @resource_production[ir.item] = production
    end
    self.outposts.each do |outpost|
      @resource_production = outpost.resource_production(@resource_production)
    end
    @resource_production
  end

  def resource_consumption
    return @resource_consumption if @resource_consumption
    @resource_consumption = {}
    self.mass_productions.each do |mp|
      mp.raw_materials.keys.each do |item|
        consumption = @resource_consumption[item]
        consumption = 0 unless consumption
        consumption += mp.raw_materials[item]
        @resource_consumption[item] = consumption
      end if mp.raw_materials
    end
    @resource_consumption
  end

  def best_resource_for_item(item)
    resources_for_item(item).empty? ? nil : resources_for_item(item).first
  end

  def resources_for_item(item)
    return @resources_for_items[item] if @resources_for_items && @resources_for_items[item]
    @resources_for_items = {} unless @resources_for_items
    @resources_for_items[item] = BaseResource.min_week_yields(5).where(["item_id = ? AND base_id IN (?)",item.id, [self.id] + self.outposts.map{|b| b.id} ]).sort{|a,b| b.next_complex_output <=> a.next_complex_output}
  end

  def grouped_item_groups
    return @grouped_item_groups if @grouped_item_groups
    @grouped_item_groups = {}
    self.item_groups.each do |ig|
      item_group = @grouped_item_groups[ig.group_id]
      item_group = {:group_id => ig.group_id, :group_name => ig.name, :items => [], :total_mass => 0, :total_cargo => 0, :total_life => 0, :total_ores => 0} unless item_group
      item_group[:items] << ig
      if ig.total_mass
        item_group[:total_mass] += ig.total_mass
        item_group[:total_cargo] += ig.total_mass if ig.item.cargo?
        item_group[:total_life] += ig.total_mass if ig.item.life?
        item_group[:total_ores] += ig.total_mass if ig.item.ore?
      end
      @grouped_item_groups[ig.group_id] = item_group
    end
    @grouped_item_groups
  end

  def competitive_buyable_goods
    return [] unless self.trade_good_value_per_mu
    @competitive_buyable_goods ||= Item.sellable_goods.select{|i| !selling_item(i) && i.competitive_buy_price?(self)}
  end

  def worth_buying?(item)
    return @worth_buying[item] if @worth_buying && @worth_buying[item]
    @worth_buying = {} if @worth_buying.nil?
    supply = weeks_supply_of_same_category(item)
    @worth_buying[item] = (supply.nil? || supply == "< 1" || supply < MAXIMUM_WEEKS_TRADE_RESERVES)
  end

  def weeks_supply_of_same_category(item)
    return @weekly_supply[item] if @weekly_supply && @weekly_supply[item]
    @weekly_supply = {} if @weekly_supply.nil?
    if item.trade_good?
      return @weekly_supply[item] = trade_metrics_by_type("trade_goods")[:weeks_for_high] if item.high_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("trade_goods")[:weeks_for_medium] if item.medium_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("trade_goods")[:weeks_for_low] if item.low_value_good?(self)
    elsif item.life_good?
      return @weekly_supply[item] = trade_metrics_by_type("life_goods")[:weeks_for_high] if item.high_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("life_goods")[:weeks_for_medium] if item.medium_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("life_goods")[:weeks_for_low] if item.low_value_good?(self)
    elsif item.drug?
      return @weekly_supply[item] = trade_metrics_by_type("drugs")[:weeks_for_high] if item.high_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("drugs")[:weeks_for_medium] if item.medium_value_good?(self)
      return @weekly_supply[item] = trade_metrics_by_type("drugs")[:weeks_for_low] if item.low_value_good?(self)
    end
    nil
  end

  def competitive_buyable_goods_orders
    orders = []
    competitive_buyable_goods.each do |buyable_good|
      if worth_buying?(buyable_good)
        orders << PhoenixOrder.market_buy(buyable_good.id, buyable_good.recommended_buy_volume(self), buyable_good.recommended_buy_price(self))
      end
    end
    orders
  end

  def set_inventory
    @personnel = []
    @inventory = []
    @raw_materials = []
    @trade_items = []
    BaseItem.includes(:item).where(:base_id => self.id).order("items.name ASC").each do |bi|
      puts "#{bi.item} -> #{bi.category}"
      case bi.category
      when BaseItem::PERSONNEL
        @personnel << bi
      when BaseItem::INVENTORY
        @inventory << bi
      when BaseItem::RAW_MATERIALS
        @raw_materials << bi
      when BaseItem::TRADE_ITEMS
        @trade_items << bi
      end
    end
  end

  def personnel
    set_inventory unless defined?(@personnel)
    @personnel
  end

  def inventory
    set_inventory unless defined?(@inventory)
    @inventory
  end

  def raw_materials
    set_inventory unless defined?(@raw_materials)
    @raw_materials
  end

  def trade_items
    set_inventory unless defined?(@trade_items)
    @trade_items
  end

  def count_item(item)
    sbi = BaseItem.where(:base_id => self.id, :item_id => item.id).first
    sbi ? sbi.quantity : 0
  end

  def trade_metrics_by_type(trade_type)
    metric = {}
    unless send("#{trade_type.singularize}_value_per_mu".to_sym).nil?
      metric[:high_total] = high_value_goods(send("non_local_#{trade_type}".to_sym)).sum{|sbi| sbi.quantity * sbi.item.local_price(self)}.round(0).to_i
      metric[:medium_total] = medium_value_goods(send("non_local_#{trade_type}".to_sym)).sum{|sbi| sbi.quantity * sbi.item.local_price(self)}.round(0).to_i
      metric[:low_total] = low_value_goods(send("non_local_#{trade_type}".to_sym)).sum{|sbi| sbi.quantity * sbi.item.local_price(self)}.round(0).to_i
      metric[:max_sales] = (send("#{trade_type.singularize}_max_income".to_sym) / 4).round(0).to_i
      if metric[:max_sales] && metric[:max_sales] > 0
        metric[:weeks_for_high] = metric[:high_total] ? (metric[:high_total] < metric[:max_sales] ? "< 1" : (metric[:high_total] / metric[:max_sales]).round(0).to_i) : 0
        metric[:weeks_for_medium] = metric[:medium_total] ? (metric[:medium_total] < metric[:max_sales] ? "< 1" : (metric[:medium_total] / metric[:max_sales]).round(0).to_i) : 0
        metric[:weeks_for_low] = metric[:low_total] ? (metric[:low_total] < metric[:max_sales] ? "< 1" : (metric[:low_total] / metric[:max_sales]).round(0).to_i) : 0
      else
        metric[:weeks_for_high] = "N/A"
        metric[:weeks_for_medium] = "N/A"
        metric[:weeks_for_low] = "N/A"
      end
    end
    metric
  end

  def trade_report_metrics
    return @trade_report_metrics unless @trade_report_metrics.nil?
    @trade_report_metrics = {}
    @trade_report_metrics[:trade_goods] = trade_metrics_by_type("trade_goods")
    @trade_report_metrics[:life_goods] = trade_metrics_by_type("life_goods")
    @trade_report_metrics[:drugs] = trade_metrics_by_type("drugs")
    @trade_report_metrics
  end

  def non_local_trade_goods
    @non_local_trade_goods ||= trade_items.select{|sbi| sbi.item.trade_good? && !sbi.item.local?(self)}
  end

  def non_local_life_goods
    @non_local_life_goods ||= trade_items.select{|sbi| sbi.item.life_good? && !sbi.item.civilian? && !sbi.item.local?(self)}
  end

  def non_local_drugs
    @non_local_drugs ||= trade_items.select{|sbi| sbi.item.drug? && !sbi.item.local?(self)}
  end

  def high_value_goods(list)
    list.select{|sbi| sbi.item.high_value_good?(self)}
  end

  def medium_value_goods(list)
    list.select{|sbi| sbi.item.medium_value_good?(self)}
  end

  def low_value_goods(list)
    list.select{|sbi| sbi.item.low_value_good?(self)}
  end

  def clear_base_items!
    self.base_items.destroy_all
    self.item_groups.destroy_all
    save!
  end

  def set_base_items!(item,quantity,category)
    return unless item && quantity && category
    si = BaseItem.where(base_id: self.id, item_id: item.id).first
    si ||= BaseItem.create(base_id: self.id, item_id: item.id)
    si.quantity = quantity
    si.category = category
    si.save!
    Rails.logger.info "#{self} - #{quantity} x #{item} - #{category}"
    si.quantity
  end

  def best_buys
    @best_buys ||= self.market_buys.select{|mi| mi.item.is_best_buyer?(self)}.sort{|a,b| b.item.best_profit <=> a.item.best_profit}
  end

  def best_sells
    @best_sells ||= self.market_sells.select{|mi| mi.item.is_best_buyer?(self)}.sort{|a,b| b.item.best_profit <=> a.item.best_profit}
  end

  def buying_item(item)
    MarketBuy.where(item_id: item.id, base_id: self.id).first
  end
  def selling_item(item)
    MarketSell.where(item_id: item.id, base_id: self.id).first
  end

  def starting_trade_routes
    @starting_trade_routes ||= TradeRoute.starting_from(self)
  end

  def ending_trade_routes
    @ending_trade_routes ||= TradeRoute.ending_at(self)
  end
  
  def total_profit_of_starting_routes
    @total_profit_of_starting_routes ||= starting_trade_routes.sum{|tr| tr.barge_weekly_profit}
  end

  def average_profit_of_starting_routes
    @average_profit_of_starting_routes ||= (starting_trade_routes.size > 0 ? total_profit_of_starting_routes / starting_trade_routes.size : 0)
  end

  def path_to_base(base)
    return 0 if base.star_system == self.star_system
    Path.find_quickest(self.star_system, base.star_system)
  end

  def time_to_base(base)
    return TradeRoute::IN_SYSTEM_TRAVEL_APPROX if self.star_system == base.star_system
    p = path_to_base(base)
    return 1000 if p.nil?
    return 0 if p == 0
    p.tu_cost + TradeRoute::IN_SYSTEM_TRAVEL_APPROX
  end

  def time_from_system(star_system)
    return TradeRoute::IN_SYSTEM_TRAVEL_APPROX if self.star_system == star_system
    p = star_system.path_to(self.star_system)
    return 1000 if p.nil?
    p.tu_cost + TradeRoute::IN_SYSTEM_TRAVEL_APPROX
  end

  def nearest_stopping_points(destination_base)
    near_to_this_base = nearest_affiliation_bases
    near_to_that_base = destination_base.nearest_affiliation_bases
    near_to_both = []
    near_to_this_base.each do |sb|
      near_to_both << sb if near_to_that_base.include?(sb) && sb.star_system != self.star_system && sb.star_system != destination_base.star_system
    end
    near_to_both.sort{|a,b| (time_to_base(a) + destination_base.time_to_base(a) <=> time_to_base(b) + destination_base.time_to_base(b))}
  end

  def best_stopping_point(destination_base)
    list = nearest_stopping_points(destination_base)
    list.size > 0 ? list.first : nil
  end

  def nearest_affiliation_bases
    @nearest_affiliation_bases ||= Nexus.config.affiliation.bases.select{|sb| sb != self && sb.starbase? }.sort {|a, b|time_to_base(a) <=> time_to_base(b)}
  end

  def move_to_order
    @move_to_order ||= PhoenixOrder.move_to_planet(self.star_system_id, self.celestial_body.cbody_id) if self.celestial_body
  end

  def squadron_move_to_orders
    @squadron_move_to_orders ||= [PhoenixOrder.squadron_start, PhoenixOrder.move_to_base(self.id), PhoenixOrder.squadron_stop]
  end

  def sell_to_order(item,quantity)
    PhoenixOrder.sell(self.id, item.id, quantity)
  end

  def buy_from_order(item,quantity)
    PhoenixOrder.buy(self.id, item.id, quantity)
  end

  def set_item_group_orders(item_group, items)
    return nil unless item_group && items
    orders = [PhoenixOrder.create_item_group(item_group)]
    items.each do |item, quantity|
      orders << PhoenixOrder.set_item_group(item_group, item.id, quantity)
    end
    orders
  end

  def squadron_move_items_orders(item_group, destination_base)
    orders = [PhoenixOrder.squadron_start, PhoenixOrder.navigation_hazard_status, PhoenixOrder.pickup_from_item_group(self.id, item_group[:total_mass], item_group[:group_id]), PhoenixOrder.squadron_stop]
    if self.star_system == destination_base.star_system
      orders << PhoenixOrder.wait_for_tus(240)
      orders = orders + squadron_move_to_orders
      orders = orders[0..(orders.size - 2)]
    else
      path = path_to_base(destination_base)
      orders = path.to_orders(orders,true)
      if path.path_points.last.jump_link
        orders = orders[0..(orders.size - 2)] + [PhoenixOrder.move_to_base(destination_base.id), PhoenixOrder.squadron_stop]
      else
        orders = orders + [PhoenixOrder.wait_for_tus(240)] + destination_base.squadron_move_to_orders
      end
      orders = orders[0..(orders.size - 2)]
    end
    orders << PhoenixOrder.deliver_items(destination_base.id, item_group[:total_mass])
    orders << PhoenixOrder.squadron_stop
    orders
  end

  def fetch_turn!
    begin
      turn = get_turn!
    rescue Exception => e
      Rails.logger.error "Failed to fetch turn for #{to_s} because #{e}"
      Rails.logger.error e.backtrace.join("\n")
      turn = nil
    end
    return false unless turn
    clear_base_items!
    # PLANETARY
    if turn.planetary_report['Trade']
      self.trade_good_value_per_mu = turn.planetary_report['Trade']['Trade Goods']['Value/MU']
      self.life_good_value_per_mu = turn.planetary_report['Trade']['Lifeforms']['Value/MU']
      self.drug_value_per_mu = turn.planetary_report['Trade']['Drugs']['Value/MU']
      self.trade_good_low_value = turn.planetary_report['Trade']['Trade Goods']['Low']
      self.trade_good_high_value = turn.planetary_report['Trade']['Trade Goods']['High']
      self.life_good_low_value = turn.planetary_report['Trade']['Lifeforms']['Low']
      self.life_good_high_value = turn.planetary_report['Trade']['Lifeforms']['High']
      self.drug_low_value = turn.planetary_report['Trade']['Drugs']['Low']
      self.drug_high_value = turn.planetary_report['Trade']['Drugs']['High']
      self.trade_good_max_income = turn.planetary_report['Trade']['Trade Goods']['Max']
      self.life_good_max_income = turn.planetary_report['Trade']['Lifeforms']['Max']
      self.drug_max_income = turn.planetary_report['Trade']['Drugs']['Max']
    end
    # PERSONNEL
    Rails.logger.info "#{turn.personnel.size} personnel items"
    turn.personnel.each {|item, quantity| set_base_items!(item, quantity, BaseItem::PERSONNEL)}
    # INVENTORY
    Rails.logger.info "#{turn.inventory.size} inventory items"
    turn.inventory.each {|item, quantity| set_base_items!(item, quantity, BaseItem::INVENTORY)}
    # RAW MATERIALS
    Rails.logger.info "#{turn.raw_materials.size} raw material items"
    turn.raw_materials.each {|item, quantity| set_base_items!(item, quantity, BaseItem::RAW_MATERIALS)}
    # TRADE ITEMS
    Rails.logger.info "#{turn.trade_items.size} trade items"
    turn.trade_items.each {|item, quantity| set_base_items!(item, quantity, BaseItem::TRADE_ITEMS)}
    # ITEM GROUPS
    turn.item_groups.keys.each do |ig_id|
      ig_name = turn.item_groups[ig_id][:name]
      ig_items = turn.item_groups[ig_id][:items]
      Rails.logger.info "#{ig_items.size} items in #{ig_name} (#{ig_id})"
      ig_items.keys.each do |item|
        ItemGroup.create!(:base_id => self.id, :name => ig_name, :group_id => ig_id, :item_id => item.id, :quantity => ig_items[item])
      end
    end
    # RESOURCES
    update_item_resources!(turn)
    # MASS PRODUCTION
    self.mass_productions.destroy_all
    turn.mass_production.each do |mp|
      MassProduction.create!(:base_id => self.id, :item_id => mp[:item].id, :factories => mp[:factories], :status => mp[:status])
    end
    self.touch
    self.save
    self
  end

end
