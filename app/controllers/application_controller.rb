class ApplicationController < ActionController::Base
  before_filter :check_configuration, unless: :skip_configuration_checks
  before_filter :check_setup, unless: :skip_setup_checks
  before_filter :update_notice

  def skip_configuration_checks
    false
  end

  def skip_setup_checks
    false
  end

  def update_notice
    if Nexus.config
      flash[:notice] = Nexus.config.update_notice if Nexus.config.update_notice
      flash[:error] = Nexus.config.update_error if Nexus.config.update_error
      Nexus.config.update_attributes!(:update_notice => nil, :update_error => nil)
    end
  end

  def flash_errors(message, errors)
    error_message = "#{message}:\n<ul>\n"
    errors.keys.each do |key|
      errors[key].each do |value|
        error_message = "#{error_message}<li>#{key} #{value}</li>\n"
      end
      error_message = "#{error_message}</ul></li>\n"
    end
    flash[:error] = error_message.html_safe
  end

  def check_configuration
    redirect_to main_app.configuration_index_path unless Nexus.config
  end

  def check_setup
    redirect_to main_app.setting_up_path if Nexus.config && Nexus.config.doing_setup?
  end
end
