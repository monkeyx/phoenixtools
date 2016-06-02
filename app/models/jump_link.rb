class JumpLink < ActiveRecord::Base
	belongs_to :from, class_name: "StarSystem"
	belongs_to :to, class_name: "StarSystem"
	validates :jumps, numericality: {only_integer: true}
	# hidden
	validates :tu_cost, numericality: {only_integer: true}

	has_many :path_points, dependent: :destroy

	scope :star_system, ->(star_system) { where(["from_id = ? OR to_id = ?", star_system.id, star_system.id])}
	scope :from_system, ->(star_system) { where(from_id: star_system.id)}
	scope :to_system, ->(star_system) { where(to_id: star_system.id)}

	def to_s
		"#{self.from}->#{self.to} (#{self.jumps} jumps)"
	end

	def star_system
		self.from
	end

	def known?
		!from.nil? && !to.nil?
	end

	def self.link_systems!(a, b, jumps=1)
		return if JumpLink.exists?(from_id: a.id, to_id: b.id, jumps: jumps)
		JumpLink.create!(:from_id => a.id, :to_id => b.id, :jumps => jumps)
		JumpLink.create!(:from_id => b.id, :to_id => a.id, :jumps => jumps)
	end

	def self.quickest_jump(system_a, system_b)
		list = JumpLink.where(:from_id => system_a.id, :to_id => system_b.id).order('jumps ASC')
		list.size > 0 ? list.first : nil
	end

	def self.extrapolate_until_no_more!
		Rails.logger.info "Extrapolating jump links..."

		pass = 0
		total_links_count = 0
		while (links_added = extrapolate!) > 0
		  pass += 1
		  Rails.logger.info "Pass #{pass} added #{links_added} new jump links"
		  total_links_count += links_added
		end

		Rails.logger.info "Finished extrapolating adding #{total_links_count} new jump links."
	end

	def self.extrapolate!
		new_links_count = 0
		StarSystem.all.each do |star_system|
		  Rails.logger.info "Examing links from #{star_system.name} (#{star_system.id})"
		    JumpLink.where(from_id: star_system.id).each do |jump_link|
		      if jump_link.jumps < 4
		        JumpLink.where(from_id: jump_link.to_id).each do |next_link|
		          qj = quickest_jump(star_system, next_link.to)
		          unless jump_link.from == next_link.to && (qj.nil? || jump_link.jumps + 1 < qj.jumps)
		            combined_jumps = jump_link.jumps + next_link.jumps
		            if combined_jumps <= 4 && (qj.nil? || combined_jumps < qj.jumps)
		              new_link = JumpLink.create!(:from_id => jump_link.from_id, :to_id => next_link.to_id, :hidden => true, :jumps => combined_jumps)
		              Rails.logger.info "Added new link between #{jump_link.from} to #{next_link.to} in #{combined_jumps} jumps"
		              new_links_count += 1
		            end
		          end
		        end
		      end
		    end
		end
		new_links_count
	end
end
