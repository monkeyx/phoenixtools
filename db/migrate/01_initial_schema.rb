class InitialSchema < ActiveRecord::Migration
  def change
    create_table :nexus do |t|
      t.string :nexus_user, :default => ''
      t.string :nexus_password, :default => ''
      t.integer :affiliation_id, :default => 0
      t.boolean :setup_complete, :default => false
      t.boolean :updating_market, :default => false
      t.boolean :updating_turns, :default => false
      t.boolean :updating_items, :default => false
      t.boolean :updating_jump_map, :default => false
      t.boolean :updating_cbodies, :default => false
      t.timestamp :core_fetched_at
      t.timestamp :market_fetched_at
      t.timestamp :turns_fetched_at
      t.timestamp :items_fetched_at
      t.timestamp :jump_map_fetched_at
      t.timestamp :cbodies_fetched_at
      t.integer :user_id, :default => 0
      t.string :xml_code, :default => ''
      t.string :setup_notice, :default => ''
      t.string :setup_error, :default => ''
      t.string :update_notice, :default => ''
      t.string :update_error, :default => ''
      t.timestamps
    end

    create_table :affiliations do |t|
      t.string :tag
      t.string :name

      t.timestamps
    end
    add_index :affiliations, :tag
    add_index :affiliations, :name

    create_table :affiliation_attributes do |t|
      t.integer :affiliation_id
      t.string :attr_key, :default => ''
      t.string :attr_value, :default => ''

      t.timestamps
    end
    add_index :affiliation_attributes, :affiliation_id
    add_index :affiliation_attributes, :attr_key

    create_table :items do |t|
      t.string :name
      t.integer :mass, :default => 0
      t.integer :item_type_id
      t.boolean :attributes_fetched, :default => false

      t.timestamps
    end
    add_index :items, :name
    add_index :items, :item_type_id

    create_table :item_attributes do |t|
      t.integer :item_id
      t.string :attr_key, :default => ''
      t.string :attr_value, :default => ''

      t.timestamps
    end

    add_index :item_attributes, :item_id
    add_index :item_attributes, :attr_key

    create_table :item_groups do |t|
      t.integer :base_id
      t.string :name
      t.integer :group_id
      t.integer :item_id
      t.integer :quantity, :default => 0

      t.timestamps
    end

    add_index :item_groups, :base_id
    add_index :item_groups, :name
    add_index :item_groups, :group_id
    add_index :item_groups, :item_id

    create_table :item_types do |t|
      t.string :name

      t.timestamps
    end

    add_index :item_types, :name

    create_table :peripheries do |t|
      t.string :name

      t.timestamps
    end

    add_index :peripheries, :name

    create_table :periphery_distances do |t|
      t.integer :periphery_id 
      t.integer :to_id
      t.integer :trade_distance_modifier, :default => 0

      t.timestamps
    end

    add_index :periphery_distances, :periphery_id
    add_index :periphery_distances, :to_id

    create_table :star_systems do |t|
      t.string :name
      t.integer :affiliation_id
      t.integer :periphery_id

      t.timestamps
    end
    add_index :star_systems, :name
    add_index :star_systems, :affiliation_id
    add_index :star_systems, :periphery_id

    create_table :jump_links do |t|
      t.integer :from_id
      t.integer :to_id
      t.integer :jumps, :default => 0
      t.boolean :hidden, :default => false
      t.integer :tu_cost, :default => 50

      t.timestamps
    end

    add_index :jump_links, :from_id
    add_index :jump_links, :to_id

    create_table :celestial_bodies do |t|
      t.string :name
      t.integer :cbody_id
      t.integer :star_system_id
      t.string :cbody_type, :default => ''
      t.integer :ring, :default => 0
      t.integer :quad, :default => 0
      t.integer :width, :default => 0
      t.integer :height, :default => 0

      t.timestamps
    end
    add_index :celestial_bodies, :name
    add_index :celestial_bodies, :cbody_id
    add_index :celestial_bodies, :star_system_id

    create_table :celestial_body_attributes do |t|
      t.integer :celestial_body_id
      t.string :attr_key, :default => ''
      t.string :attr_value, :default => ''

      t.timestamps
    end

    add_index :celestial_body_attributes, :celestial_body_id
    add_index :celestial_body_attributes, :attr_key

    create_table :sectors do |t|
      t.integer :celestial_body_id
      t.integer :x, :default => 0
      t.integer :y, :default => 0
      t.string :terrain, :default => ''

      t.timestamps
    end

    add_index :sectors, :celestial_body_id
    add_index :sectors, :x
    add_index :sectors, :y

    create_table :bases do |t|
      t.string :name
      t.integer :affiliation_id
      t.integer :star_system_id
      t.integer :celestial_body_id
      t.integer :hiports, :default => 0
      t.float :patches, :default => 0
      t.integer :docks, :default => 0
      t.integer :maintenance, :default => 0
      t.float :trade_good_value_per_mu, :default => 0
      t.float :life_good_value_per_mu, :default => 0
      t.float :drug_value_per_mu, :default => 0
      t.float :trade_good_low_value, :default => 0
      t.float :trade_good_high_value, :default => 0
      t.float :life_good_low_value, :default => 0
      t.float :life_good_high_value, :default => 0
      t.float :drug_low_value, :default => 0
      t.float :drug_high_value, :default => 0
      t.float :trade_good_max_income, :default => 0
      t.float :life_good_max_income, :default => 0
      t.float :drug_max_income, :default => 0
      t.string :race, :default => ''
      t.boolean :blacklist, :default => false
      t.boolean :starbase, :default => false
      t.integer :hub_id

      t.timestamps
    end

    add_index :bases, :name
    add_index :bases, :affiliation_id
    add_index :bases, :star_system_id
    add_index :bases, :celestial_body_id
    add_index :bases, :starbase
    add_index :bases, :race
    add_index :bases, :maintenance
    add_index :bases, :patches
    add_index :bases, :hub_id

    create_table :base_items do |t|
      t.integer :base_id
      t.integer :item_id
      t.integer :quantity, :default => 0
      t.string :category, :default => ''

      t.timestamps
    end

    add_index :base_items, :base_id
    add_index :base_items, :item_id
    add_index :base_items, :category

    create_table :mass_productions do |t|
      t.integer :base_id
      t.integer :item_id
      t.integer :factories, :default => 0
      t.string :status, :default => ''

      t.timestamps
    end

    add_index :mass_productions, :base_id
    add_index :mass_productions, :item_id
    add_index :mass_productions, :status

    create_table :market_buys do |t|
      t.integer :item_id
      t.integer :base_id
      t.integer :quantity, :default => 0
      t.float :price, :default => 0

      t.timestamps
    end

    add_index :market_buys, :item_id
    add_index :market_buys, :base_id

    create_table :market_sells do |t|
      t.integer :item_id
      t.integer :base_id
      t.integer :quantity, :default => 0
      t.float :price, :default => 0

      t.timestamps
    end

    add_index :market_sells, :item_id
    add_index :market_sells, :base_id

    create_table :trade_routes do |t|
      t.integer :from_id
      t.integer :to_id
      t.integer :item_id
      t.integer :path_id
      t.integer :barges_assigned, :default => 0
      t.timestamps
    end

    add_index :trade_routes, :from_id
    add_index :trade_routes, :to_id
    add_index :trade_routes, :item_id

    create_table :wormholes do |t|
      t.integer :star_system_id
      t.integer :to_id
      t.integer :celestial_body_id

      t.timestamps
    end

    add_index :wormholes, :star_system_id
    add_index :wormholes, :to_id
    add_index :wormholes, :celestial_body_id

    create_table :stargates do |t|
      t.integer :star_system_id
      t.integer :celestial_body_id

      t.timestamps
    end

    add_index :stargates, :star_system_id
    add_index :stargates, :celestial_body_id

    create_table :stargate_routes do |t|
      t.integer :from_id
      t.integer :to_id

      t.timestamps
    end

    add_index :stargate_routes, :from_id
    add_index :stargate_routes, :to_id

    create_table :paths do |t|
      t.integer :from_id
      t.integer :to_id
      t.integer :tu_cost, :default => 0

      t.timestamps
    end

    add_index :paths, :from_id
    add_index :paths, :to_id

    create_table :path_points do |t|
      t.integer :path_id
      t.integer :jump_link_id
      t.integer :wormhole_id
      t.integer :stargate_id
      t.integer :sequence, :default => 0

      t.timestamps
    end

    add_index :path_points, :path_id
    add_index :path_points, :sequence

    create_table :positions do |t|
      t.string :name
      t.integer :star_system_id
      t.integer :celestial_body_id
      t.integer :quad, :default => 0
      t.integer :ring, :default => 0
      t.boolean :landed, :default => false
      t.boolean :orbit, :default => false
      t.integer :size, :default => 0
      t.string :size_type, :default => ''
      t.string :design, :default => ''
      t.string :position_class, :default => ''

      t.timestamps
    end

    add_index :positions, :star_system_id
    add_index :positions, :celestial_body_id
    add_index :positions, :quad
    add_index :positions, :ring
    add_index :positions, :landed
    add_index :positions, :orbit
    add_index :positions, :design
    add_index :positions, :position_class

    create_table :base_resources do |t|
      t.integer :item_id
      t.integer :base_id
      t.integer :ore_mines, :default => 0
      t.integer :resource_complexes, :default => 0
      t.integer :resource_drop, :default => 0
      t.integer :resource_id, :default => 0
      t.integer :resource_size, :default => 0
      t.float :resource_yield, :default => 0
    end

    add_index :base_resources, :item_id
    add_index :base_resources, :base_id

    create_table :delayed_jobs, :force => true do |table|
      table.integer  :priority, :default => 0, :null => false # Allows some jobs to jump to the front of the queue
      table.integer  :attempts, :default => 0, :null => false # Provides for retries, but still fail eventually.
      table.text     :handler, :null => false                 # YAML-encoded string of the object that will do work
      table.text     :last_error                              # reason for last failure (See Note below)
      table.datetime :run_at                                  # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      table.datetime :locked_at                               # Set when a client is working on this object
      table.datetime :failed_at                               # Set when all retries have failed (actually, by default, the record is deleted instead)
      table.string   :locked_by                               # Who is working on this object (if locked)
      table.string   :queue                                   # The name of the queue this job is in
      table.timestamps
    end

    add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'
  end
end
