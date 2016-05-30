class HomeController < ApplicationController

  def skip_setup_checks
    action_name == 'setting_up' || action_name == 'setup_status'
  end

  def index
  end

  def fetch_daily
    Nexus.config.schedule_daily_update!
    redirect_to action: :index
  end

  def fetch_full
    Nexus.config.schedule_full_update!
    redirect_to action: :index
  end

  def setting_up
    unless Nexus.config && Nexus.config.doing_setup?
      redirect_to action: :index
    end
  end

  def setup_status
    respond_to do |format|
      json = {updating: Nexus.config.doing_setup?, notice: Nexus.config.setup_notice, error: Nexus.config.setup_error }
      format.js { render json: json}
      format.html { redirect_to action: :setting_up }
    end
  end
end
