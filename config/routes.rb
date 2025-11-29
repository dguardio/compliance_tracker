Rails.application.routes.draw do
  namespace :admin do
    resources :policies do
      resources :policy_links, only: [:new, :create, :destroy]
      resources :comments, only: [:create, :destroy]
    end
    resources :regulations do
      resources :comments, only: [:create, :destroy]
      collection do
        delete :bulk_delete
      end
      member do
        get 'versions/:version_id', to: 'regulations#version', as: :version
        get 'diff/:id', to: 'regulations#download_diff', as: :diff
        get :workspace
        get :evidence
      end
    end

    resources :compliance_tables, only: [:index]
    
    resources :custom_columns do
      collection do
        post :extract_all
      end
      member do
        post :extract
        post :use_template
      end
    end
    
    resources :table_templates, only: [:create] do
      member do
        post :apply
      end
    end
    
    resource :compliance_assistant, only: [] do
      post :chat
    end
    
    resources :organization_regulations, only: [:index, :create, :destroy] do
      collection do
        get :available
      end
      member do
        patch :update_status
      end
    end
    
    resources :regulatory_data_sources do
      collection do
        delete :bulk_delete
        get :discover
        post :discover
      end
    end

    resources :evidence, only: [:index]
  end
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
      member do
        post :suggest_requirements
      end
      resources :compliance_requirements, only: %i[index show new create edit update destroy] do
        resources :comments, only: [:create, :destroy]
        resources :compliance_controls, only: %i[index show new create edit update destroy] do
          resources :comments, only: [:create, :destroy]
          member do
            get :assignment_form
            post :assign
          end
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

    # Workflow management
    resources :workflow_templates do
      resources :workflow_steps, only: %i[create edit update destroy] do
        member do
          patch :update_position
          get :condition_form
        end
      end
      resources :workflow_transitions, only: %i[create destroy]
    end
  end

  post 'switch_organization', to: 'organizations#switch_organization', as: :switch_organization

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

  # Regulation Reviews
  resources :regulation_reviews, only: %i[index show update] do
    member do
      post :classify
    end
  end

  # My Tasks (Kanban)
  resources :tasks, only: [:index, :show]
  patch 'tasks/:id/update_status', to: 'tasks#update_status', as: :update_task_status

  # Feedbacks
  resources :feedbacks

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
