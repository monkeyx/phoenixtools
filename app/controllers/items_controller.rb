class ItemsController < ApplicationController
  def index
    unless params[:manufacturing].blank?
      @items = Item.producable
      @paginate = false
    else
      @items = Item.page(params[:page] || 1)
      @paginate = true
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  def show
    @item = Item.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end

  def fetch
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item.fetch_item_attributes!
        expire_action :action => :show
        format.html { redirect_to @item, notice: 'Item data was successfully fetched.' }
        format.json { head :no_content }
      else
        format.html { redirect_to @item, notice: 'Failed to fetch item data.' }
        format.json { head :no_content }
      end
    end
  end

  def profitable_but_no_trade_route
    @items = Item.profitable_but_no_trade_route

    respond_to do |format|
      format.html # profitable_but_no_trade_route.html.erb
      format.json { render json: @items }
    end
  end

  def periphery_goods
    unless params[:periphery].blank?
      @items = Item.periphery_goods(params[:periphery])
      @middleman_orders = []
      @items.each{|i| @middleman_orders = @middleman_orders + i.middleman_orders}
      render :action => :index
    else
      redirect_to :action => :index
    end
  end

  def race_preferred_goods
    unless params[:race].blank?
      @items = Item.race_preferred_goods(params[:race])
      @middleman_orders = []
      @items.each{|i| @middleman_orders = @middleman_orders + i.middleman_orders}
      render :action => :index
    else
      redirect_to :action => :index
    end
  end
end
