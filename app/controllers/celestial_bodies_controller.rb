class CelestialBodiesController < ApplicationController
  def show
    @celestial_body = CelestialBody.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @celestial_body }
    end
  end

  def fetch
    @celestial_body = CelestialBody.find(params[:id])
    respond_to do |format|
      if @celestial_body.fetch_cbody_data!
        format.html { redirect_to @celestial_body, notice: 'Celestial Body data was successfully fetched.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @celestial_body, notice: 'Failed to fetch Celestial Body data.' }
        format.json { head :no_content }
      end
    end
  end

  def gpi
    @number_of_ships = params[:ships]
    @celestial_body = CelestialBody.find(params[:id])
    respond_to do |format|
      unless @number_of_ships
        format.html { redirect_to @celestial_body, notice: 'Specify number of ships.' }
        format.json { head :no_content }
      else
        @number_of_ships = @number_of_ships.to_i
        format.html # gpi.html.erb
        format.json { render json: @celestial_body }
      end
    end
  end

  def search
    if request.post?
      @star_system = StarSystem.find_by_id(params[:star_system_id])
      @terrain = params[:terrain] ? params[:terrain].select{|t| !t.blank?} : nil
      @celestial_body_type = params[:cbody_type]
      if params[:cbody_attributes]
        @attributes = []
        params[:cbody_attributes].each do |ca|
          key = ca['key']
          unless key.blank?
            key = key + ':' unless key[-1,1] == ':' || key == 'Radiation' || key.index('(')
            @attributes << {:key => key, :value => ca['value'], :op => ca['op']}
          end
        end
      else
        @attributes = nil
      end
      if @star_system
        case @celestial_body_type
        when CelestialBody::PLANET
          @cbodies = CelestialBody.star_system(@star_system).planets_only
        when CelestialBody::MOON
          @cbodies = CelestialBody.star_system(@star_system).planets_or_moons_only
        when CelestialBody::GAS_GIANT
          @cbodies = CelestialBody.star_system(@star_system).gas_giants_only
        else
          @cbodies = CelestialBody.star_system(@star_system)
        end
      else
        case @celestial_body_type
        when CelestialBody::PLANET
          @cbodies = CelestialBody.planets_only
        when CelestialBody::MOON
          @cbodies = CelestialBody.planets_or_moons_only
        when CelestialBody::GAS_GIANT
          @cbodies = CelestialBody.gas_giants_only
        else
          @cbodies = CelestialBody.all
        end
      end

      unless params[:populated].blank?
        @attributes << {:key => params[:populated], :value => 'There is a sentient population.', :op => '='}
      end

      @cbodies = CelestialBody.filter_by_terrain(@terrain,@cbodies) unless @terrain.nil? || @terrain.empty?
      @cbodies = CelestialBody.filter_by_attribute(@attributes,@cbodies) unless @attributes.nil? || @attributes.empty?
    end
  end
end
