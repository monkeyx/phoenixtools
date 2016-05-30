class StarSystemsController < ApplicationController
  def index
    @star_systems = StarSystem.includes(:periphery).order('peripheries.name ASC, star_systems.name ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @star_systems }
    end
  end

  def show
    @star_system = StarSystem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @star_system }
    end
  end

  def shortest_path
    if params[:start] && params[:end]
      @start_system = StarSystem.find(params[:start])
      @end_system = StarSystem.find(params[:end])
      @path = @start_system.path_to(@end_system)
    else
      redirect_to :action => :index
    end
  end

  def fetch_cbodies
    @star_system = StarSystem.find(params[:id])
    respond_to do |format|
      if @star_system.fetch_cbodies!(true)
        format.html { redirect_to @star_system, notice: 'Star system cbodies fetched successfully.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @star_system, notice: 'Failed to fetch star system cbodies.' }
        format.json { head :no_content }
      end
    end
  end
end
