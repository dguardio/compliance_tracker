Rails.application.routes.draw do
  devise_for :users

  # Multi-tenancy routes
  resources :organizations do
    resources :departments, only: %i[index show new create edit update destroy] do
      resources :teams, only: %i[index show new create edit update destroy] do
        resources :units, only: %i[index show new create edit update destroy] do
        end
      end
    end
    resources :users, only: %i[index show new create edit update destroy]

    # Roles management
    resources :roles do
      collection do
        get :get_resources
      end
      member do
        post :assign_user
        delete :remove_user
      end
    end

    # Permissions management
    resources :permissions do
      collection do
        get :get_resources
        get :get_grantee_options
      end
    end
  end

  # User registration (for adding users to organizations)
  namespace :users do
    resources :registrations, only: %i[new create]
  end

  # Dashboard
  get 'dashboard', to: 'dashboard#dashboard', as: :dashboard

  # Root route
  root 'home#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
