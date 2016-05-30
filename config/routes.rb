Phoenixtools::Application.routes.draw do
  resources :trade_routes, only: [:index] do
    collection do
      post 'find'
    end
    member do
      get 'orders'
      get 'assign_barge'
    end
  end

  resources :bases, only: [:index, :show] do
    member do
      get 'resource_production'
      get 'mass_production'
      post 'item_group_to_base'
      get 'middleman'
      get 'competitive_buys'
      get 'inventory'
      get 'item_groups'
      get 'trade_items_report'
      get 'fetch_turn'
      post 'set_item_group'
      get 'outposts'
      post 'set_hub'
    end
    collection do
      get 'path_to_base'
      get 'shipping_jobs'
      get 'mining_jobs'
    end
  end

  resources :star_systems, only: [:index, :show] do
    collection do
      get 'shortest_path'
    end
    member do
      get 'fetch_cbodies'
    end
  end

  resources :items, only: [:index, :show] do
    collection do
      get 'profitable_but_no_trade_route'
      get 'periphery_goods'
      get 'race_preferred_goods'
    end
    member do
      post 'fetch'
    end
  end

  resources :celestial_bodies, only: [:show] do
    member do
      get 'fetch'
      get 'gpi'
    end
    collection do
      match 'search', via: [:get, :post]
    end
  end

  resources :nexus, only: [:new, :edit, :update, :create, :index], path: 'configuration', as: 'configuration'

  mount RailsAdmin::Engine => '/data', :as => 'rails_admin'

  get 'fetch_daily', to: 'home#fetch_daily', as: 'fetch_daily'
  get 'fetch_full', to: 'home#fetch_full', as: 'fetch_full'

  get 'setting_up', to: 'home#setting_up', as: 'setting_up'
  get 'setup_status', to: 'home#setup_status', as: 'setup_status'

  root 'home#index'

end
