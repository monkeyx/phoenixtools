class TradeRoutesController < ApplicationController
  def index
    @trade_routes = TradeRoute.sort_by_profitability(TradeRoute.filtered_by_barge_slots_available(TradeRoute.filtered_by_time(300, TradeRoute.filter_out_blacklisted)))
    params[:keys] = true
  end

  def find
    if params[:start]
      @no_keys = params[:keys].blank?
      @filter_out_aff = params[:filter_out_aff].blank? ? nil : Affiliation::MOH
      @start_system = StarSystem.find(params[:start])
      @trade_routes = TradeRoute.find_by_items_near_system(nil, @start_system, @no_keys, @filter_out_aff)
      if params[:lifeform] == 'yes'
        @trade_routes = TradeRoute.filtered_by_lifeform(@trade_routes)
      else
        @trade_routes = TradeRoute.filtered_by_not_lifeform(@trade_routes)
      end
      if params[:keys] != 'yes'
        @trade_routes = TradeRoute.filtered_by_no_keys(@trade_routes)
      end
      respond_to do |format|
        format.html
      end
    else
      redirect_to :action => :index
    end
  end

  def orders
    if params[:id]
      @trade_route = TradeRoute.find(params[:id])
      if params[:from]
        @from = StarSystem.find(params[:from])
      else
        @from = @trade_route.from.star_system
      end
      respond_to do |format|
        format.html
      end
    else
      redirect_to :action => :index
    end
  end

  def assign_barge
    if params[:id]
      @trade_route = TradeRoute.find(params[:id])
      @trade_route.assign_barge!
      respond_to do |format|
        redirect_to :action => :index
      end
    else
      redirect_to :action => :index
    end
  end
end
