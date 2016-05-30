class NexusController < ApplicationController

  def skip_configuration_checks
    true
  end

  def index
    if @nexus
      redirect_to edit_configuration_path(@nexus)
    else
      @nexus = Nexus.new
      render action: :new
    end
  end

  def new
    if @nexus
      redirect_to edit_configuration_path(@nexus)
    else
      @nexus = Nexus.new
    end
  end

  def create
    @nexus = Nexus.new(nexus_params)
    unless @nexus.save
      flash_errors("There were problems with your configuration", @nexus.errors)
      render configuration_index_path
    else
      @nexus.schedule_setup!
      @nexus.schedule_full_update!
      redirect_to setting_up_path
    end
  end

  def edit
  end

  def update
    unless @nexus.update_attributes(nexus_params)
      flash_errors("There were problems with your configuration", @nexus.errors)
      render edit_configuration_path(@nexus)
    else
      @nexus.schedule_setup!
      redirect_to setting_up_path
    end
  end

  def nexus_params
    params.require(:nexus).permit(:nexus_user, :nexus_password, :affiliation_id, :user_id, :xml_code)
  end
end
