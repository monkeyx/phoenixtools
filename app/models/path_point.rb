class PathPoint < ActiveRecord::Base
	belongs_to :path
	belongs_to :jump_link
	belongs_to :wormhole
	belongs_to :stargate
	validates :sequence, numericality: {only_integer: true}

	def to_s
		if self.jump_link
			self.jump_link.to_s
		elsif self.wormhole
			self.wormhole.to_s
		elsif self.stargate
			self.stargate.to_s
		end
	end

	def connection
		return @connection unless @connection.nil?
		@connection = self.jump_link unless self.jump_link.nil?
		@connection = self.stargate unless self.stargate.nil?
		@connection = self.wormhole unless self.wormhole.nil?
		@connection
	end

	def from
		connection.from
	end

	def to
		connection.to
	end

	def add_orders(orders=[])
		if self.jump_link
		orders << PhoenixOrder.jump(to.id)
		elsif self.stargate
		orders << PhoenixOrder.move_to_planet(from.id, self.stargate.cbody_id)
		orders << PhoenixOrder.enter_stargate(to.id)
		elsif self.wormhole
		orders << PhoenixOrder.move_to_planet(from.id, self.wormhole.cbody_id)
		orders << PhoenixOrder.enter_wormhole
		end
		orders
	end

	def add_squad_orders(orders=[])
		if self.jump_link
		orders << PhoenixOrder.jump(to.id)
		elsif self.stargate || self.wormhole
		cbody_id = self.stargate ? self.stargate.cbody_id : self.wormhole.cbody_id
		orders << PhoenixOrder.move_to_planet(from.id, cbody_id)
		orders << PhoenixOrder.squadron_stop
		orders << PhoenixOrder.wait_for_tus(120)
		orders << PhoenixOrder.squadron_start
		orders << PhoenixOrder.enter_stargate(to.id)
		orders << PhoenixOrder.squadron_stop
		orders << PhoenixOrder.wait_for_tus(240)
		end
		orders
	end
end
