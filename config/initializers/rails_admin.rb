RailsAdmin.config do |config|

  config.main_app_name = Proc.new { |controller| [ "Phoenix Tools", "Data Admin - #{controller.params[:action].try(:titleize)}" ] }

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end

  config.excluded_models << "Nexus"
  config.label_methods << :to_s

  config.model "AffiliationAttribute" do
    parent Affiliation
  end

  config.model "BaseItem" do
    parent Base
  end

  config.model "BaseResource" do
    parent Base
  end

  config.model "CelestialBodyAttribute" do
    parent CelestialBody
  end

  config.model "ItemAttribute" do
    parent Item
  end

  config.model "ItemGroup" do 
    parent Base
  end

  config.model "MassProduction" do
    parent Base
  end

  config.model "PathPoint" do 
    parent Path
  end

  config.model "PeripheryDistance" do 
    parent Periphery
  end

  config.model "Sector" do
    parent CelestialBody
  end

  config.model "Stargate" do
    parent StarSystem
  end

  config.model "Wormhole" do
    parent StarSystem
  end
end
