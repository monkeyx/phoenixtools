require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'nokogiri'
require 'open-uri'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Phoenixtools
  class Application < Rails::Application
    config.generators do |g|
      g.hidden_namespaces << :test_unit << :erb
      g.test_framework :rspec
    end
  end
end
