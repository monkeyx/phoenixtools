class TradeRoute < ActiveRecord::Base
  TRANSACTION_TIME_APPROX = 20
  IN_SYSTEM_TRAVEL_APPROX = 50
  MAX_TUS = 300

  BARGE_CARGO_CAPACITY = 2400
  BARGE_LIFE_CAPACITY = 1800
  BARGE_ORE_CAPACITY = 9000
  BARGE_WAGES = 5
  
	belongs_to :from, class_name: "Base"
	belongs_to :to, class_name: "Base"
	belongs_to :item
	belongs_to :path
	validates :barges_assigned, numericality: {only_integer: true}

	scope :base, ->(base) { where(["from_id = ? OR to_id = ?", base.id, base.id])}
	scope :from_system, ->(base) { where(from_id: base.id)}
	scope :to_system, ->(base) { where(to_id: base.id)}


  def self.affiliation_stats
    require 'pp'
    buyer_affs = {}
    seller_affs = {}
    TradeRoute.all.select{|tr| tr.from.affiliation && tr.to.affiliation}.each do |tr|
      tag = tr.from.affiliation.to_s
      buyer_affs[tag] ||= 0
      buyer_affs[tag] += 1
      tag = tr.to.affiliation.to_s
      seller_affs[tag] ||= 0
      seller_affs[tag] += 1
    end
    return buyer_affs, seller_affs
  end

	def to_s
		"#{self.from}->#{self.to}: #{item}"
	end

	def self.find_by_items_near_system(item_type, start_system,no_keys=false,filter_out_aff=nil)
    if no_keys
      list = filtered_by_no_keys_to_start(start_system, MAX_TUS, filtered_by_item_type(item_type, filtered_by_no_keys(filtered_by_barge_slots_available(filter_out_destination_affiliation(filter_out_aff, filter_out_blacklisted)))))
    else
      list = filtered_by_time_to_start(start_system, MAX_TUS, filtered_by_item_type(item_type,filtered_by_barge_slots_available(filter_out_destination_affiliation(filter_out_aff, filter_out_blacklisted))))
    end
    sort_by_profitability(list)
  end

  def self.filter_out_blacklisted(list=all.to_a)
    list.select{|tr| !tr.to.blacklist? }
  end

  def self.filter_out_destination_affiliation(affiliation, list=all.to_a)
    return list unless affiliation
    list.select{|tr| tr.to.affiliation != affiliation }
  end

  def self.filtered_by_no_keys(list=all.to_a)
    list.select{|tr| !tr.requires_gate_keys?}
  end

  def self.filtered_by_barge_slots_available(list=all.to_a)
    list.select{|tr|tr.barge_slots_available?}
  end

  def self.filtered_by_item_type(item_type,list=all.to_a)
    return list unless item_type
    list.select{|tr| tr.item.item_type == item_type}
  end

  def self.filtered_by_time_to_start(start_system, max_time=250, list=all.to_a)
    list.select{|tr| tr.travel_time + tr.time_to_start(start_system) <= max_time}
  end

  def self.filtered_by_no_keys_to_start(start_system,max_time=250,list=all.to_a)
    list.select{|tr| !tr.require_keys_to_start(start_system) && tr.travel_time + tr.time_to_start(start_system) <= max_time}
  end

  def self.filtered_by_time(max_time=MAX_TUS,list=all.to_a)
    list.select{|tr| tr.travel_time <= max_time}
  end

  def self.sort_by_profitability(list=all.to_a)
    list.sort{|a,b| b.barge_weekly_profit <=> a.barge_weekly_profit}
  end

  def self.sorted_by_nearest(start_system,list=all.to_a)
    list = list.select{|tr| start_system == tr.from.star_system || !start_system.path_to(tr.from.star_system).nil?}
    list.sort{|a,b| a.time_to_start(start_system) <=> b.time_to_start(start_system)}
  end

  def self.starting_from(base)
    sort_by_profitability(TradeRoute.includes(:item, :from, :to, :path).where({:from_id => base.id}))
  end

  def self.ending_at(base)
    sort_by_profitability(TradeRoute.includes(:item, :from, :to, :path).where({:to_id => base.id}))
  end

  def barge_slots_available?
    self.barges_assigned.nil? || self.barges_assigned < barges_max
  end

  def require_keys_to_start(from_system)
    path = Path.find_quickest(from_system, self.from.star_system)
    path.nil? ? nil : path.requires_gate_keys?
  end

  def time_to_start(from_system)
    if self.from.star_system == from_system
      IN_SYSTEM_TRAVEL_APPROX
    elsif self.from.star_system.nil?
      1000
    else
      t = Path.find_shortest_time(from_system, self.from.star_system)
      if t.nil?
        t = 1000
      else
        t += IN_SYSTEM_TRAVEL_APPROX
      end
      t
    end
  end

  def assign_barge!
    self.barges_assigned = 0 unless self.barges_assigned
    self.barges_assigned += 1
    save!
  end

  def barges_max
    @barges_max ||= (total_volume < quantity_per_barge ? 1 : (total_volume / quantity_per_barge).to_i + (total_volume % quantity_per_barge != 0 ? 1 : 0))
  end

  def barge_weekly_profit
    return @barge_weekly_profit unless @barge_weekly_profit.nil?
    if travel_time > 0
      max_trips = (300.0 / travel_time.to_f)
      @barge_weekly_profit = ((max_trips * quantity_per_barge * profit_per_mu) - BARGE_WAGES).round(0).to_i
    else
      @barge_weekly_profit = total_profit
    end
    @barge_weekly_profit = total_profit if @barge_weekly_profit > total_profit
    @barge_weekly_profit
  end

  def quantity_per_barge
    @quantity_per_barge ||= (self.item.mass == 0 ? 10000000 : if self.item.item_type.nil? || self.item.item_type.cargo?
      (BARGE_CARGO_CAPACITY / (self.item.mass ? self.item.mass : 1)).to_i
    elsif self.item.item_type.life?
      (BARGE_LIFE_CAPACITY / self.item.mass).to_i
    elsif self.item.item_type.ore?
      (BARGE_ORE_CAPACITY / self.item.mass).to_i
    elsif self.item.item_type.personnel?
      (BARGE_LIFE_CAPACITY / self.item.mass).to_i
    else
      BARGE_CARGO_CAPACITY
    end)
  end

  def travel_time
    @travel_time ||= (self.path.nil? ? 0 : self.path.tu_cost) + TRANSACTION_TIME_APPROX + IN_SYSTEM_TRAVEL_APPROX
  end

  def profit_per_mu
    @profit_per_mu ||= (self.item.mass == 0 ? profit_per_unit : (profit_per_unit / (self.item.mass ? self.item.mass.to_f : 1)))
  end

  def profit_per_unit
    @profit_per_unit ||= ((buyers_price - sellers_price) - (self.item.personnel? ? 2 : 0))
  end

  def total_volume
    @total_volume ||= (buying_quantity > selling_quantity ? selling_quantity : buying_quantity)
  end

  def total_profit
    @total_profit ||= (profit_per_unit * total_volume).round(0).to_i
  end

  def profits_remaining
    return @profits_remaining if @profits_remaining
    @profits_remaining = self.barges_assigned.nil? ? total_profit : total_profit - (barge_weekly_profit * self.barges_assigned)
    @profits_remaining = 0 if @profits_remaining < 0
    @profits_remaining
  end

  def requires_gate_keys?
    self.path.nil? || self.path.requires_gate_keys?
  end

  def self.generate!
    TradeRoute.destroy_all
    Rails.logger.info "Generating trade routes...."
    count = 0
    MarketSell.all.each do |sell_item|
      MarketBuy.where({:item_id => sell_item.item.id}).each do |buy_item|
        unless buy_item.base.blacklist? || buy_item.base.star_system.nil?
          if sell_item.price < buy_item.price
            if sell_item.base.star_system == buy_item.base.star_system
              tr = TradeRoute.create!(:from_id => sell_item.base_id, :to_id => buy_item.base_id, :item_id => sell_item.item_id, :path_id => nil)
              count += 1
            elsif  !sell_item.base.star_system.nil?
              p = Path.find_quickest(sell_item.base.star_system, buy_item.base.star_system)
              unless p.nil?
                tr = TradeRoute.create!(:from_id => sell_item.base_id, :to_id => buy_item.base_id, :item_id => sell_item.item_id, :path_id => p.id)
                count += 1
              end
            end
          end
          if tr
            Rails.logger.info "Route Added: #{tr.item} $#{sell_item.price}ea. @ #{sell_item.base} to $#{buy_item.price}ea. @ #{buy_item.base} - weekly barge profit $#{tr.barge_weekly_profit}"
          end
        end
      end
    end
    Rails.logger.info "Finished generating #{count} trade routes."
    count
  end

  def buyers_price
    @buying_price ||= buying.price
  end

  def buying_quantity
    @buying_quantity ||= buying.quantity
  end

  def sellers_price
    @selling_price ||= selling.price
  end

  def selling_quantity
    @selling_quantity ||= selling.quantity
  end

  def available_volume
    barges_assigned && barges_assigned > 0 ? total_volume - (quantity_per_barge * barges_assigned) : total_volume
  end

  def to_orders(from_system)
    orders = [PhoenixOrder.navigation_hazard_status]
    unless self.from.star_system == from_system
      path_to_start = from_system.path_to(self.from.star_system)
      orders = path_to_start.to_orders(orders)
    end
    previous_point = nil
    orders << self.from.move_to_order
    orders << self.from.buy_from_order(self.item, available_volume)
    orders = self.path.to_orders(orders) if self.path
    orders << self.to.move_to_order
    orders << self.to.sell_to_order(self.item, available_volume)
    orders << PhoenixOrder.wait_for_tus
    orders
  end

  private
  def buying
    @buying ||= self.to.buying_item(self.item)
  end

  def selling
    @selling ||= self.from.selling_item(self.item)
  end
end
