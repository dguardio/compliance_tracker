Rails.application.routes.draw do
  namespace :admin do
    resources :agent_traces, only: [:index, :show]
    authenticate :user, ->(u) { u.super_admin? } do
      mount Flipper::UI.app(Flipper) => '/flipper'
    end
    resources :organizations do
      member do
        post :enrich
      end
      resources :departments, only: [:new, :create, :show, :index]
      resources :teams, only: [:show]
    end
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
        post :apply_template
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
        post :preview_config
        post :run_discovery
      end
    end

    resources :evidence, only: [:index]
  end
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Provider management (top-level resource)
  resources :providers do
    collection do
      get :recommendations
      post :auto_assign
      post :bulk_assign
    end
  end

  # Multi-tenancy routes
    namespace :ai do
      resources :profile_generations, only: [:create]
    end

    resources :organizations do
    member do
      post :enrich
    end
    # Direct organization-level resources
    resources :providers, only: %i[index show new create edit update destroy]
    resources :departments, only: %i[index show new create edit update destroy]
    resources :teams, only: %i[index show new create edit update destroy]
    resources :units, only: %i[index show new create edit update destroy]
    resources :users, only: %i[index show new create edit update destroy] do
      collection do
        get :import, to: 'users/imports#new'
        post :import, to: 'users/imports#create'
      end
    end
    
    resources :policies do
      resources :policy_links, only: [:new, :create, :destroy]
      resources :comments, only: [:create, :destroy]
    end

    # Nested hierarchical resources
    resources :departments, only: %i[index show new create edit update destroy] do
      resources :teams, only: %i[index show new create edit update destroy] do
        resources :units, only: %i[index show new create edit update destroy] do
        end
      end
    end



    resources :compliance_frameworks do
      collection do
        get :import
        post :process_import
      end
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
    
    resources :evidence_requests do
      member do
        get :download_all
      end
    end

    # Findings & CAPA
    resources :findings do
      member do
        patch :close
        patch :reopen
      end
      resources :corrective_actions, only: [:create, :update] do
        member do
          patch :complete
        end
      end
    end

    # Control Testing
    resources :control_testing do
      member do
        post :execute
      end
      resources :test_executions, only: [:show, :update] do
        member do
          patch :review
        end
      end
    end

    # Policy Attestation Campaigns
    resources :attestation_campaigns do
      member do
        post :launch
        patch :close
      end
    end

    # Obligation Management
    resources :obligations

    # Incident Management
    resources :incidents do
      member do
        patch :resolve
        patch :close
      end
      resources :lesson_learneds, only: [:create]
    end

    # Maturity Assessment
    resources :maturity, only: [:index, :show, :update] do
      collection do
        post :snapshot
      end
    end

    # Cross-Framework Harmonization
    resources :harmonization, only: [:index] do
      collection do
        get :matrix
        get :delta
        get :suggestions
        post :create_mapping
        delete :destroy_mapping
      end
    end

    # Workflow Intelligence & Analytics
    resources :workflow_analytics, only: [:index] do
      collection do
        get :bottlenecks
        get :workload
      end
    end

    # Policy Gap Analysis
    resources :policy_gap, only: [:index] do
      collection do
        get :analyze
        post :draft
      end
    end

    # Regulatory Impact Simulation
    resources :impact_simulations, only: [:index, :show] do
      collection do
        post :simulate
      end
      member do
        post :create_findings
      end
    end

    # Executive Reports
    resources :executive_reports, only: [:index, :show, :new, :create] do
      member do
        patch :publish
      end
    end

    # Questionnaire Autofill
    resources :questionnaire, only: [:index, :show] do
      collection do
        post :upload
        post :approve_answer
      end
      member do
        get :export
      end
    end

    # Vendor Risk Management (TPRM)
    resources :vendors do
      member do
        post :assess
      end
    end

    # Evidence Collection Agents
    resources :evidence_agents, only: [:index] do
      collection do
        get :checks
      end
    end

    # Continuous Monitoring Dashboard
    resources :monitoring_dashboard, only: [:index]

    # External Integrations (Jira, Linear, ServiceNow)
    resources :external_integrations do
      member do
        post :sync
        post :create_ticket
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

    # Setup Wizard
    resources :setup, only: [:index, :show, :update], controller: 'organizations/setup'
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

  resources :standard_requirements, only: [:index] do
    collection do
      get :search
    end
    member do
      post :adopt
    end
  end

  # Risk Dashboard
    get 'risk_dashboard', to: 'risk_dashboard#index', as: :risk_dashboard
    get 'risk_dashboard/my_risks', to: 'risk_dashboard#my_risks'
    get 'risk_dashboard/organization_risks', to: 'risk_dashboard#organization_risks', as: :organization_risks

  # Regulation Reviews
  resources :regulation_reviews, only: %i[index show update] do
    member do
      post :classify
    end
  end

  # User-facing Attestations
  resources :attestations, only: [:show] do
    member do
      patch :attest
    end
  end

  # Tenant-facing Regulation Library
  resources :regulation_library, only: [:index, :show] do
    collection do
      get :discover
    end
    member do
      post :adopt
      delete :unadopt
    end
  end

  # Evidence Freshness Dashboard
  resources :evidence_freshness, only: [:index] do
    collection do
      post :request_refresh
    end
  end

  # My Tasks (Kanban)
  resources :tasks, only: [:index, :show]
  patch 'tasks/:id/update_status', to: 'tasks#update_status', as: :update_task_status

  # Feedbacks
  # Compliance Exports (CSV)
  scope :exports, controller: :exports, as: :exports do
    get :frameworks
    get :requirements
    get :controls
    get :risk_assessments
  end

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
