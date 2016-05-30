# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 1) do

  create_table "affiliation_attributes", force: :cascade do |t|
    t.integer  "affiliation_id"
    t.string   "attr_key",       default: ""
    t.string   "attr_value",     default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "affiliation_attributes", ["affiliation_id"], name: "index_affiliation_attributes_on_affiliation_id"
  add_index "affiliation_attributes", ["attr_key"], name: "index_affiliation_attributes_on_attr_key"

  create_table "affiliations", force: :cascade do |t|
    t.string   "tag"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "affiliations", ["name"], name: "index_affiliations_on_name"
  add_index "affiliations", ["tag"], name: "index_affiliations_on_tag"

  create_table "base_items", force: :cascade do |t|
    t.integer  "base_id"
    t.integer  "item_id"
    t.integer  "quantity",   default: 0
    t.string   "category",   default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "base_items", ["base_id"], name: "index_base_items_on_base_id"
  add_index "base_items", ["category"], name: "index_base_items_on_category"
  add_index "base_items", ["item_id"], name: "index_base_items_on_item_id"

  create_table "base_resources", force: :cascade do |t|
    t.integer "item_id"
    t.integer "base_id"
    t.integer "ore_mines",          default: 0
    t.integer "resource_complexes", default: 0
    t.integer "resource_drop",      default: 0
    t.integer "resource_id",        default: 0
    t.integer "resource_size",      default: 0
    t.float   "resource_yield",     default: 0.0
  end

  add_index "base_resources", ["base_id"], name: "index_base_resources_on_base_id"
  add_index "base_resources", ["item_id"], name: "index_base_resources_on_item_id"

  create_table "bases", force: :cascade do |t|
    t.string   "name"
    t.integer  "affiliation_id"
    t.integer  "star_system_id"
    t.integer  "celestial_body_id"
    t.integer  "hiports",                 default: 0
    t.float    "patches",                 default: 0.0
    t.integer  "docks",                   default: 0
    t.integer  "maintenance",             default: 0
    t.float    "trade_good_value_per_mu", default: 0.0
    t.float    "life_good_value_per_mu",  default: 0.0
    t.float    "drug_value_per_mu",       default: 0.0
    t.float    "trade_good_low_value",    default: 0.0
    t.float    "trade_good_high_value",   default: 0.0
    t.float    "life_good_low_value",     default: 0.0
    t.float    "life_good_high_value",    default: 0.0
    t.float    "drug_low_value",          default: 0.0
    t.float    "drug_high_value",         default: 0.0
    t.float    "trade_good_max_income",   default: 0.0
    t.float    "life_good_max_income",    default: 0.0
    t.float    "drug_max_income",         default: 0.0
    t.string   "race",                    default: ""
    t.boolean  "blacklist",               default: false
    t.boolean  "starbase",                default: false
    t.integer  "hub_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bases", ["affiliation_id"], name: "index_bases_on_affiliation_id"
  add_index "bases", ["celestial_body_id"], name: "index_bases_on_celestial_body_id"
  add_index "bases", ["hub_id"], name: "index_bases_on_hub_id"
  add_index "bases", ["maintenance"], name: "index_bases_on_maintenance"
  add_index "bases", ["name"], name: "index_bases_on_name"
  add_index "bases", ["patches"], name: "index_bases_on_patches"
  add_index "bases", ["race"], name: "index_bases_on_race"
  add_index "bases", ["star_system_id"], name: "index_bases_on_star_system_id"
  add_index "bases", ["starbase"], name: "index_bases_on_starbase"

  create_table "celestial_bodies", force: :cascade do |t|
    t.string   "name"
    t.integer  "cbody_id"
    t.integer  "star_system_id"
    t.string   "cbody_type",     default: ""
    t.integer  "ring",           default: 0
    t.integer  "quad",           default: 0
    t.integer  "width",          default: 0
    t.integer  "height",         default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "celestial_bodies", ["cbody_id"], name: "index_celestial_bodies_on_cbody_id"
  add_index "celestial_bodies", ["name"], name: "index_celestial_bodies_on_name"
  add_index "celestial_bodies", ["star_system_id"], name: "index_celestial_bodies_on_star_system_id"

  create_table "celestial_body_attributes", force: :cascade do |t|
    t.integer  "celestial_body_id"
    t.string   "attr_key",          default: ""
    t.string   "attr_value",        default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "celestial_body_attributes", ["attr_key"], name: "index_celestial_body_attributes_on_attr_key"
  add_index "celestial_body_attributes", ["celestial_body_id"], name: "index_celestial_body_attributes_on_celestial_body_id"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "item_attributes", force: :cascade do |t|
    t.integer  "item_id"
    t.string   "attr_key",   default: ""
    t.string   "attr_value", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_attributes", ["attr_key"], name: "index_item_attributes_on_attr_key"
  add_index "item_attributes", ["item_id"], name: "index_item_attributes_on_item_id"

  create_table "item_groups", force: :cascade do |t|
    t.integer  "base_id"
    t.string   "name"
    t.integer  "group_id"
    t.integer  "item_id"
    t.integer  "quantity",   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_groups", ["base_id"], name: "index_item_groups_on_base_id"
  add_index "item_groups", ["group_id"], name: "index_item_groups_on_group_id"
  add_index "item_groups", ["item_id"], name: "index_item_groups_on_item_id"
  add_index "item_groups", ["name"], name: "index_item_groups_on_name"

  create_table "item_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_types", ["name"], name: "index_item_types_on_name"

  create_table "items", force: :cascade do |t|
    t.string   "name"
    t.integer  "mass",               default: 0
    t.integer  "item_type_id"
    t.boolean  "attributes_fetched", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["item_type_id"], name: "index_items_on_item_type_id"
  add_index "items", ["name"], name: "index_items_on_name"

  create_table "jump_links", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.integer  "jumps",      default: 0
    t.boolean  "hidden",     default: false
    t.integer  "tu_cost",    default: 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jump_links", ["from_id"], name: "index_jump_links_on_from_id"
  add_index "jump_links", ["to_id"], name: "index_jump_links_on_to_id"

  create_table "market_buys", force: :cascade do |t|
    t.integer  "item_id"
    t.integer  "base_id"
    t.integer  "quantity",   default: 0
    t.float    "price",      default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "market_buys", ["base_id"], name: "index_market_buys_on_base_id"
  add_index "market_buys", ["item_id"], name: "index_market_buys_on_item_id"

  create_table "market_sells", force: :cascade do |t|
    t.integer  "item_id"
    t.integer  "base_id"
    t.integer  "quantity",   default: 0
    t.float    "price",      default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "market_sells", ["base_id"], name: "index_market_sells_on_base_id"
  add_index "market_sells", ["item_id"], name: "index_market_sells_on_item_id"

  create_table "mass_productions", force: :cascade do |t|
    t.integer  "base_id"
    t.integer  "item_id"
    t.integer  "factories",  default: 0
    t.string   "status",     default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mass_productions", ["base_id"], name: "index_mass_productions_on_base_id"
  add_index "mass_productions", ["item_id"], name: "index_mass_productions_on_item_id"
  add_index "mass_productions", ["status"], name: "index_mass_productions_on_status"

  create_table "nexus", force: :cascade do |t|
    t.string   "nexus_user",          default: ""
    t.string   "nexus_password",      default: ""
    t.integer  "affiliation_id",      default: 0
    t.boolean  "setup_complete",      default: false
    t.boolean  "updating_market",     default: false
    t.boolean  "updating_turns",      default: false
    t.boolean  "updating_items",      default: false
    t.boolean  "updating_jump_map",   default: false
    t.boolean  "updating_cbodies",    default: false
    t.datetime "core_fetched_at"
    t.datetime "market_fetched_at"
    t.datetime "turns_fetched_at"
    t.datetime "items_fetched_at"
    t.datetime "jump_map_fetched_at"
    t.datetime "cbodies_fetched_at"
    t.integer  "user_id",             default: 0
    t.string   "xml_code",            default: ""
    t.string   "setup_notice",        default: ""
    t.string   "setup_error",         default: ""
    t.string   "update_notice",       default: ""
    t.string   "update_error",        default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "path_points", force: :cascade do |t|
    t.integer  "path_id"
    t.integer  "jump_link_id"
    t.integer  "wormhole_id"
    t.integer  "stargate_id"
    t.integer  "sequence",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "path_points", ["path_id"], name: "index_path_points_on_path_id"
  add_index "path_points", ["sequence"], name: "index_path_points_on_sequence"

  create_table "paths", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.integer  "tu_cost",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "paths", ["from_id"], name: "index_paths_on_from_id"
  add_index "paths", ["to_id"], name: "index_paths_on_to_id"

  create_table "peripheries", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "peripheries", ["name"], name: "index_peripheries_on_name"

  create_table "periphery_distances", force: :cascade do |t|
    t.integer  "periphery_id"
    t.integer  "to_id"
    t.integer  "trade_distance_modifier", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "periphery_distances", ["periphery_id"], name: "index_periphery_distances_on_periphery_id"
  add_index "periphery_distances", ["to_id"], name: "index_periphery_distances_on_to_id"

  create_table "positions", force: :cascade do |t|
    t.string   "name"
    t.integer  "star_system_id"
    t.integer  "celestial_body_id"
    t.integer  "quad",              default: 0
    t.integer  "ring",              default: 0
    t.boolean  "landed",            default: false
    t.boolean  "orbit",             default: false
    t.integer  "size",              default: 0
    t.string   "size_type",         default: ""
    t.string   "design",            default: ""
    t.string   "position_class",    default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "positions", ["celestial_body_id"], name: "index_positions_on_celestial_body_id"
  add_index "positions", ["design"], name: "index_positions_on_design"
  add_index "positions", ["landed"], name: "index_positions_on_landed"
  add_index "positions", ["orbit"], name: "index_positions_on_orbit"
  add_index "positions", ["position_class"], name: "index_positions_on_position_class"
  add_index "positions", ["quad"], name: "index_positions_on_quad"
  add_index "positions", ["ring"], name: "index_positions_on_ring"
  add_index "positions", ["star_system_id"], name: "index_positions_on_star_system_id"

  create_table "sectors", force: :cascade do |t|
    t.integer  "celestial_body_id"
    t.integer  "x",                 default: 0
    t.integer  "y",                 default: 0
    t.string   "terrain",           default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sectors", ["celestial_body_id"], name: "index_sectors_on_celestial_body_id"
  add_index "sectors", ["x"], name: "index_sectors_on_x"
  add_index "sectors", ["y"], name: "index_sectors_on_y"

  create_table "star_systems", force: :cascade do |t|
    t.string   "name"
    t.integer  "affiliation_id"
    t.integer  "periphery_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "star_systems", ["affiliation_id"], name: "index_star_systems_on_affiliation_id"
  add_index "star_systems", ["name"], name: "index_star_systems_on_name"
  add_index "star_systems", ["periphery_id"], name: "index_star_systems_on_periphery_id"

  create_table "stargate_routes", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stargate_routes", ["from_id"], name: "index_stargate_routes_on_from_id"
  add_index "stargate_routes", ["to_id"], name: "index_stargate_routes_on_to_id"

  create_table "stargates", force: :cascade do |t|
    t.integer  "star_system_id"
    t.integer  "celestial_body_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stargates", ["celestial_body_id"], name: "index_stargates_on_celestial_body_id"
  add_index "stargates", ["star_system_id"], name: "index_stargates_on_star_system_id"

  create_table "trade_routes", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.integer  "item_id"
    t.integer  "path_id"
    t.integer  "barges_assigned", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trade_routes", ["from_id"], name: "index_trade_routes_on_from_id"
  add_index "trade_routes", ["item_id"], name: "index_trade_routes_on_item_id"
  add_index "trade_routes", ["to_id"], name: "index_trade_routes_on_to_id"

  create_table "wormholes", force: :cascade do |t|
    t.integer  "star_system_id"
    t.integer  "to_id"
    t.integer  "celestial_body_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wormholes", ["celestial_body_id"], name: "index_wormholes_on_celestial_body_id"
  add_index "wormholes", ["star_system_id"], name: "index_wormholes_on_star_system_id"
  add_index "wormholes", ["to_id"], name: "index_wormholes_on_to_id"

end
