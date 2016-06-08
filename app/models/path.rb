class Path < ActiveRecord::Base
	MAX_PATH_POINTS = 5
	MAX_TU = 300

	JUMP_COST = 50
	STARGATE_COST = 100
	WORMHOLE_COST = 100

	belongs_to :from, class_name: "StarSystem"
	belongs_to :to, class_name: "StarSystem"
	validates :tu_cost, numericality: {only_integer: true}

	has_many :path_points, dependent: :destroy
	has_many :trade_routes, dependent: :destroy

	scope :star_system, ->(star_system) { where(["from_id = ? OR to_id = ?", star_system.id, star_system.id])}
	scope :from_system, ->(star_system) { where(from_id: star_system.id)}
	scope :to_system, ->(star_system) { where(to_id: star_system.id)}
	scope :empty, -> { where(tu_cost: 0)}

	def to_s
		"#{self.from}->#{self.to}"
	end

	def self.find_quickest(from, to)
		return nil unless from && to
		list = Path.where({:from_id => from.id, :to_id => to.id}).order('tu_cost ASC')
		list && list.size > 0 ? list.first : nil
	end

	def self.find_shortest_time(from,to)
		quickest = find_quickest(from,to)
		quickest ? quickest.tu_cost : nil
	end

	def self.generate!
		Path.destroy_all
		PathPoint.destroy_all

		LOG.info "Generating navigation paths..."
		StarSystem.all.each do |from|
		  generate_paths!(from)
		end
		LOG.info "Finished generating #{Path.count} paths."
		Path.count
	end

	def self.make_path!(start_system, target_system, path)
		transaction do
			if path.empty?
				raise "Path #{start_system} to #{target_system} is empty"
			end
			puts ''
			p = Path.create!(:from_id => start_system.id, :to_id => target_system.id, :tu_cost => 0)
			sequence = 0
			path.each do |point|
			  sequence += 1
			  if point.is_a?(JumpLink)
			    p.tu_cost += JUMP_COST
			    pp = PathPoint.create!(:path_id => p.id, :jump_link_id => point.id, :sequence => sequence)
			  elsif point.is_a?(Stargate)
			    p.tu_cost += STARGATE_COST
			    pp = PathPoint.create!(:path_id => p.id, :stargate_id => point.id, :sequence => sequence)
			  elsif point.is_a?(Wormhole)
			    p.tu_cost += WORMHOLE_COST
			    pp = PathPoint.create!(:path_id => p.id, :wormhole_id => point.id, :sequence => sequence)
			  end
			  print '.'
			end
			p.save!
			puts ''
			LOG.info "Path: #{start_system} -> #{target_system}: #{p.tu_cost}TU / #{p.path_points.size} points"
		end
	end

	def self.generate_paths!(start_system, path = [], tu_cost = 0)
		return if start_system.nil?
		return if path.length >= MAX_PATH_POINTS # 1st sanity break out of iteration
		return if tu_cost >= MAX_TU # 2nd sanity check

		if path.length > 0
		  pp = potential_path_points(path.last.to, path.last.star_system)
		else
		  pp = potential_path_points(start_system)
		end

		pp.each do |point|
		  unless point.to_id == start_system.id || point.to.nil?
		    path_copy = Array.new(path)
		    path_copy << point
		    tu_cost = calculate_path_tu_cost(path_copy)
		    if tu_cost > 0
			    quickest_so_far = find_shortest_time(start_system, point.to)
			    if (quickest_so_far.nil? || quickest_so_far > tu_cost)
			      make_path!(start_system, point.to, path_copy) if !path_copy.empty?
			      generate_paths!(start_system, path_copy, tu_cost)
			    end
			end
		  end
		end
	end

	def self.potential_path_points(from, previous_system=nil)
		potential_points = []
		previous_system_id = previous_system ? previous_system.id : 0
		JumpLink.where(from_id: from.id).each do |jump|
		  potential_points << jump if check_potential_point(from, jump, potential_points, previous_system)
		end
		sg = Stargate.where(star_system: from.id).first
		if sg 
			StargateRoute.where(from_id: sg.star_system_id).each do |gate_route|
				potential_points << gate_route if check_potential_point(from, gate_route, potential_points, previous_system)
			end
		end
		Wormhole.where(star_system_id: from.id).each do |wormhole|
		  potential_points << wormhole if check_potential_point(from, wormhole, potential_points, previous_system)
		end
		potential_points
	end

	def self.check_potential_point(from, point, list, previous_system)
		return false if point.to.nil?
		return false unless point.known?
		return false if previous_system && previous_system.id == point.to_id
		return false if list.any? do |previous_point|
			previous_point.to_id == point.to_id || 
			(previous_point.is_a?(StargateRoute) ? previous_point.from_star_system.id : previous_point.from_id) == (point.is_a?(StargateRoute) ? point.to_star_system.id : point.to_id)
		end
		true
	end

	def requires_gate_keys?
		self.path_points.each{|p| return true if p.stargate}
		false
	end

	def to_orders(orders = [],squadron=false)
		previous_point = nil
		if squadron
		  orders << PhoenixOrder.wait_for_tus(240)
		  orders << PhoenixOrder.squadron_start
		  self.path_points.order('sequence ASC').each do |point|
		    if point.jump_link && (previous_point.nil? || !previous_point.jump_link)
		      orders << PhoenixOrder.move_to_random_jump_quad
		    end
		    orders = point.add_squad_orders(orders)
		    previous_point = point
		  end
		  unless previous_point.stargate || previous_point.wormhole
		    orders << PhoenixOrder.squadron_stop
		  else
		    orders = orders[0..(orders.size - 2)]
		  end
		else
		  self.path_points.order('sequence asc').each do |point|
		    orders << PhoenixOrder.move_to_random_jump_quad if point.jump_link && (previous_point.nil? || !previous_point.jump_link)
		    orders = point.add_orders(orders)
		    previous_point = point
		  end
		end
		orders
	end

	private
	def self.calculate_path_tu_cost(path)
		tu_cost = 0
		path.each do |point|
		  if point.is_a?(JumpLink)
		    tu_cost += JUMP_COST
		  elsif point.is_a?(Stargate)
		    tu_cost += STARGATE_COST
		  elsif point.is_a?(Wormhole)
		    tu_cost += WORMHOLE_COST
		  end
		end
		tu_cost
	end
end
