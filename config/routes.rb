# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication (existing)
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      post 'auth/refresh', to: 'auth#refresh'
      
      # User (existing)
      get 'user/profile', to: 'users#profile'
      patch 'user/profile', to: 'users#update'
      get 'user/addresses', to: 'addresses#index'
      post 'user/addresses', to: 'addresses#create'
      patch 'user/addresses/:id', to: 'addresses#update'
      delete 'user/addresses/:id', to: 'addresses#destroy'
      get 'user/laundry-preferences', to: 'laundry_preferences#show'
      put 'user/laundry-preferences', to: 'laundry_preferences#update'
      
      # Orders (NEW)
      get 'orders/next-pickup', to: 'orders#next_pickup'
      get 'orders', to: 'orders#index'
      get 'orders/:id', to: 'orders#show'
      get 'orders/:id/timeline', to: 'orders#timeline'
      post 'orders/create', to: 'orders#create'
      patch 'orders/:id', to: 'orders#update'
      post 'orders/:id/cancel', to: 'orders#cancel'
      post 'orders/:id/report-issue', to: 'orders#report_issue'
      
      # Scheduling (NEW)
      get 'scheduling/available-dates', to: 'scheduling#available_dates'
      get 'scheduling/available-time-windows', to: 'scheduling#available_time_windows'
      
      # Phase 3: Payments & Subscriptions
      get '/subscription-plans', to: 'subscription_plans#index'
      
      resources :payment_methods, only: [:index, :create, :destroy] do
        member do
          post :set_default
        end
      end
      
      resources :subscriptions, only: [:create, :update] do
        collection do
          get :current
        end
      end
      
      namespace :billing do
        resources :invoices, only: [:index, :show]
      end
    end
  end
  
  get 'health', to: proc { [200, {}, ['OK']] }
end
