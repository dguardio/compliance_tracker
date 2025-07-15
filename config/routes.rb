Rails.application.routes.draw do
  devise_for :users

  # Provider management (top-level resource)
  resources :providers do
    collection do
      get :recommendations
      post :auto_assign
      post :bulk_assign
    end
  end

  # Multi-tenancy routes
  resources :organizations do
    # Direct organization-level resources
    resources :providers, only: %i[index show new create edit update destroy]
    resources :departments, only: %i[index show new create edit update destroy]
    resources :teams, only: %i[index show new create edit update destroy]
    resources :units, only: %i[index show new create edit update destroy]
    resources :users, only: %i[index show new create edit update destroy]

    # Nested hierarchical resources
    resources :departments, only: %i[index show new create edit update destroy] do
      resources :teams, only: %i[index show new create edit update destroy] do
        resources :units, only: %i[index show new create edit update destroy] do
        end
      end
    end

    # Compliance management
    resources :compliance_frameworks do
      resources :compliance_requirements, only: %i[index show new create edit update destroy] do
        resources :compliance_controls, only: %i[index show new create edit update destroy] do
          resources :risk_assessments, only: %i[index show new create edit update destroy]
        end
      end
      resources :risk_assessments, only: %i[index show new create edit update destroy]
    end

    # Organization-level risk assessments
    resources :risk_assessments, only: %i[index show new create edit update destroy]

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

    # Document management
    resources :documents do
      member do
        patch :approve
        patch :reject
        patch :archive
        post :duplicate
        patch :submit_for_review
      end
      collection do
        get :get_requirements
        get :get_controls
      end
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :organizations, only: %i[index show] do
        resources :compliance_frameworks, only: %i[index show create update destroy] do
          resources :compliance_requirements, only: %i[index show create update destroy] do
            resources :compliance_controls, only: %i[index show create update destroy]
          end
          resources :risk_assessments, only: %i[index show create update destroy]
        end
      end
    end
  end

  # User registration (for adding users to organizations)
  namespace :users do
    resources :registrations, only: %i[new create]
  end

  # User profile management
  resource :profile, only: %i[show edit update] do
    member do
      patch :update_password
      patch :update_notifications
      patch :update_preferences
    end
  end

  # Dashboard
  get 'dashboard', to: 'dashboard#dashboard', as: :dashboard

  # Risk Dashboard
  get 'risk_dashboard', to: 'risk_dashboard#index', as: :risk_dashboard

  # Mailbox
  resources :mailboxes, only: %i[index show destroy] do
    collection do
      patch :mark_all_as_read
    end
    member do
      patch :mark_as_read
    end
  end

  # Root route
  root 'home#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
