class BasesController < ApplicationController
  before_filter :set_base, except: [:index, :path_to_base, :shipping_jobs, :mining_jobs]

  def set_base
    @base ||= Base.includes(:affiliation, :star_system, :celestial_body, :market_buys, :market_sells).find(params[:id])
  end

  def index
    case params[:sort]
    when 'name'
      order_by = 'bases.name ASC'
    when 'location'
      order_by = 'star_systems.name ASC'
    else
      order_by = 'id ASC'
    end
    if params[:show_outposts] == 'true'
      @show_outposts = true
    else
      @show_outposts = false
    end
    if params[:all_affiliations] == 'true'
      @all_affiliations = true
    else
      @all_affiliations = false
    end
    @bases = Base.includes(:affiliation, :star_system, :celestial_body)
    unless @show_outposts
      @bases = @bases.starbases
    end
    unless @all_affiliations
      @bases = @bases.where(:affiliation_id => Nexus.config.affiliation_id)
    end
    @bases = @bases.order(order_by).page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bases }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @base }
    end
  end

  def resource_production
    respond_to do |format|
      format.html #
      format.json { render json: @base }
    end
  end

  def outposts
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @base }
    end
  end

  def set_hub
    hub = @base.hub
    if params[:hub_id]
      @base.hub_id = params[:hub_id]
      @base.save
      hub ||= @base.hub
    end
    respond_to do |format|
      format.html {redirect_to hub }
      format.json { render json: @base }
    end
  end

  def mass_production
    respond_to do |format|
      format.html #
      format.json { render json: @base }
    end
  end

  def item_group_to_base
    unless params[:destination].blank? || params[:item_group].blank?
      # raise "#{params[:id]} - #{params[:destination]} - #{params[:item_group]}"
      @destination = Base.find(params[:destination])
      @item_group = @base.grouped_item_groups[params[:item_group].to_i]
    else
      redirect_to :action => :index
    end
  end

  def path_to_base
    unless (params[:start_system].blank? && params[:start_base].blank?) || params[:destination].blank?
      @start_system = StarSystem.find(params[:start_system]) if params[:start_system]
      @start_base = Base.find(params[:start_base]) if params[:start_base]
      @start_system = @start_base.star_system if @start_base
      @end_base = Base.find(params[:destination])
      @end_system = @end_base.star_system
      @path = @start_system.path_to(@end_system)
      if @path.nil?
        if @start_system == @end_base.star_system
          @orders = params[:squadron].blank? ? [@end_base.move_to_order] : @end_base.squadron_move_to_orders
        else
          @orders = []
        end
      elsif !params[:squadron].blank?
        @orders = (@path.to_orders([],true) + @end_base.squadron_move_to_orders)
      else
        @orders = (@path.to_orders + [@end_base.move_to_order])
      end
      unless params[:sell_item].blank?
        quantity = params[:sell_quantity].blank? ? 100000 : params[:sell_quantity].to_i
        @orders << PhoenixOrder.sell(@end_base.id, params[:sell_item], quantity)
        @orders << PhoenixOrder.wait_for_tus(300)
      end
    else
      redirect_to :action => :index
    end
  end

  def middleman
    @item = Item.find(params[:item])
    respond_to do |format|
      if @item && @base
        format.html
        format.json { head :no_content }
      else
        format.html { redirect_to @base, notice: 'Invalid item' }
        format.json { render json: @base, status: :unprocessable_entity }
      end
    end
  end

  def competitive_buys
    @competitive_buys = @base.competitive_buyable_goods
    @competitive_buy_orders = @base.competitive_buyable_goods_orders
    respond_to do |format|
      format.html # competitive_buys.html.erb
      format.json { render json: @base }
    end
  end

  def inventory
    respond_to do |format|
      format.html #
      format.json { render json: @base }
    end
  end

  def item_groups
    @show_cargo = true
    @show_life = true
    @show_ores = true
    respond_to do |format|
      format.html #
      format.json { render json: @base }
    end
  end

  def trade_items_report
    respond_to do |format|
      format.html # inventory.html.erb
      format.json { render json: @base }
    end
  end

  def fetch_turn
    respond_to do |format|
      if @base.fetch_turn!
        format.html { redirect_to @base, notice: 'Turn fetched' }
        format.json { render json: @base }
      else
        format.html { redirect_to @base, notice: 'Failed to fetch turn' }
        format.json { render json: @base }
      end
    end
  end

  def set_item_group
    if params[:item]
      @items = {}
      params[:item].each do |k,v|
        @items[Item.find(k)] = v.to_i unless v.blank?
      end
    end
    @group_name = params[:item_group]
    @orders = @base.set_item_group_orders(@group_name, @items)
    respond_to do |format|
      format.html
      format.json { render json: @base }
    end
  end

  def shipping_jobs
    @bases = Nexus.config.affiliation.bases.select{|sb| !sb.grouped_item_groups.empty? }
    unless params[:nearest].blank?
      @show_cargo = params[:cargo] == 'yes'
      @show_life = params[:life] == 'yes'
      @show_ores = params[:ores] == 'yes'
      @nearest = StarSystem.find(params[:nearest])
      @bases = @bases.select{|s| s.time_from_system(@nearest) < 1000}.sort{|a,b| a.time_from_system(@nearest) <=> b.time_from_system(@nearest) }
    else
      params[:cargo] = 'yes'
      params[:life] = 'yes'
      params[:ores] = 'yes'
      @show_cargo = true
      @show_life = true
      @show_ores = true
      @bases = @bases.sort{|a,b| a.name <=> b.name}
    end
    respond_to do |format|
      format.html
      format.json { render json: @base }
    end
  end

  def mining_jobs
    @jobs = []
    @rare_ores = {}
    Nexus.config.affiliation.bases.each do |base|
      base.resource_report.each do |item, report_entry|
        if report_entry[:weeks_remaining] && report_entry[:weeks_remaining] != 'Forever' && report_entry[:weeks_remaining] < 26
          if report_entry[:best_resource]
            report_entry[:base] = base
            report_entry[:item] = item
            @jobs << report_entry
          else
            @rare_ores[item] = item.resources_for_item unless @rare_ores[item]
          end
        end
      end if base.outposts.size > 0
    end
    @jobs.sort!{|a,b| a[:weeks_remaining] <=> b[:weeks_remaining]}
    respond_to do |format|
      format.html
      format.json { render json: @base }
    end
  end
end
