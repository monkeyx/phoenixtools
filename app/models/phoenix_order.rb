class PhoenixOrder
  attr_accessor :parameters

  def initialize(params=[])
    @parameters = params
  end

  def to_s
    "Order=#{@parameters.join(',')};"
  end

  def self.clear_pending
    new([1050,0])
  end

  def self.move_to_base(starbase_id,dock=false)
    new([3140,1,starbase_id,bool(dock)])
  end

  def self.move_to_planet(star_system_id, cbody_id)
    new([3130,1,star_system_id,cbody_id])
  end

  def self.enter_stargate(star_system_id, stargate_id=0)
    new([3090,1,star_system_id,stargate_id])
  end

  def self.enter_wormhole(cbody_id=0)
    new([3100,1,cbody_id])
  end

  def self.move_to_quad(quad,ring)
    new([3000,0,quad,ring])
  end

  def self.move_to_random_jump_quad
    move_to_quad([1,2,3,4].sample,10)
  end

  def self.jump(star_system_id)
    new([3080,1,star_system_id])
  end

  def self.buy(starbase_id, item_id, quantity, install=false, private=false)
    new([2040,0,starbase_id, item_id, quantity,bool(install),bool(private)])
  end

  def self.sell(starbase_id, item_id, quantity, private=false)
    new([2030,0,starbase_id, item_id, quantity, bool(private)])
  end

  def self.pickup_from_item_group(starbase_id, quantity, item_group, security='')
    new([2800,0,starbase_id, str(item_group), quantity,str(security)])
  end

  def self.deliver_items(starbase_id, quantity, item_type=0, security='', install=false)
    new([2380,0,starbase_id, item_type,quantity,str(security),bool(install)])
  end

  def self.wait_for_tus(tus=300,exact=false)
    new([2520,0,tus,bool(exact)])
  end

  def self.navigation_hazard_status(active=true)
    new([5230,0,bool(active)])
  end

  def self.market_buy(item_id, quantity, price, private=false, add=false,standing_order=0)
    new([4060,standing_order,item_id,quantity,price,bool(private),bool(add)])
  end

  def self.market_sell(item_id, quantity, price, private=false, add=false,standing_order=0)
    new([4070,standing_order,item_id,quantity,price,bool(private),bool(add)])
  end

  def self.sell_to_local_pop(item_id, quantity, set=false, standing_order=0)
    new([4340,standing_order,item_id,quantity,bool(set)])
  end

  def self.create_item_group(item_group)
    new([2760,0,str(item_group)])
  end

  def self.set_item_group(item_group, item_id, quantity,add=false, standing_order=0)
    new([2790,standing_order,str(item_group),item_id,quantity,bool(add)])
  end

  def self.gpi_row(row,start_x,end_x,ore_type=0)
    new([2500,0,ore_type,row,start_x,end_x])
  end

  def self.squadron_start(shared_turn=true)
    new([5110,0,bool(shared_turn)])
  end

  def self.squadron_stop
    new([5120,0])
  end

  private
  def self.str(v)
    '"' + v.to_s + '"'
  end

  def self.bool(v)
    v ? "True" : "False"
  end

end