Rails.application.routes.draw do
  # admin
  namespace :admin do
    resources :system_configs
    resources :spaces
    resources :users do
      get :export, on: :collection
    end
    resources :comments
    resources :leads
    resources :campaigns do
      member do
        post :toggle_campaign_recommended
      end
    end
    resources :lead_forms do
      member do
        post :toggle_lead_form_status
      end
    end
    resources :system_api_keys
    resources :tags
    resources :organizations
    resources :ssh_keys
    resources :error_logs
    resources :models, except: [:new, :create]
    resources :datasets, except: [:new, :create]

    root to: "spaces#index"
  end

  # external api
  namespace :api do
    resources :spaces, only: [:create, :destroy, :update]
  end

  # internal api
  namespace :internal_api do
    resources :organizations, only: [:create, :update] do
      collection do
        post '/new-members', to: 'organizations#new_members'
      end
    end
    resources :spaces, only: [:index, :update]
    resources :campaigns, only: [:index]
    resources :comments, only: [:create, :destroy, :index]
    resources :leads, only: [:create]
    resources :ssh_keys, only: [:create, :destroy]
    resources :git_token, only: [] do
      collection do
        post 'refresh', to: 'git-tokens/refresh'
      end
    end
    resources :users, only: [:index, :update]

    resources :models, only: [:index, :create]
    delete '/models/:namespace/:model_name', to: 'models#destroy'
    put '/models/:namespace/:model_name', to: 'models#update'

    resources :datasets, only: [:index, :create]
    delete '/datasets/:namespace/:dataset_name', to: 'datasets#destroy'

    resources :tags, only: [] do
      collection do
        get 'task-tags', to: 'tags#task_tags'
        get 'framework-tags', to: 'tags#framework_tags'
      end
    end
    # resources :discussions, only: :create
    resources :discussions, only: [:create, :index, :update]
    resources :upload, only: [:create]
  end

  # lead form
  resources :lead_forms, only: [] do
    collection do
      get 'thank-you'
    end
  end

  get 'lead_forms/form/:uuid', to: 'lead_forms#show_form'

  resources :leads, only: [:create]

  # application
  scope "(:locale)", :locale => /en|zh/ do
    root "landing_page#index"

    resources :settings, only: [] do
      collection do
        get 'profile'
        get 'git-token'
        get 'ssh-keys'
      end
    end

    resources :spaces, only: ['index', 'show'] do
      collection do
        get 'stopped'
      end
    end

    resources :campaigns, only: [:index, :show]
    resources :models, only: [:index, :new]
    resources :datasets, only: [:index, :new]
    resources :organizations, only: [:new, :show]

    get '/models/:namespace/:model_name/blob/:branch/(*path)', to: 'models#blob', format: false, defaults: {format: 'html'}
    get '/datasets/:namespace/:dataset_name/blob/:branch/(*path)', to: 'datasets#blob', format: false, defaults: {format: 'html'}
    get '/models/:namespace/:model_name/files/:branch(/*path)', to: 'models#files', defaults: { path: nil }
    get '/models/:namespace/*model_name', to: 'models#show', format: false, defaults: {format: 'html'}
    get '/datasets/:namespace/:dataset_name/files/:branch(/*path)', to: 'datasets#files', defaults: { path: nil }
    get '/datasets/:namespace/*dataset_name', to: 'datasets#show', format: false, defaults: {format: 'html'}
    
    get '/profile/:user_id', to: 'profile#index'
    get '/partners', to: 'partners#index'
    get '/partners/apply', to: 'partners#apply'
    get '/experts', to: 'experts#index'
    get '/experts/apply', to: 'experts#apply'

    get    '/signup', to: 'sessions#signup'
    get    '/login', to: 'sessions#new'
    get    '/authing/callback', to: 'sessions#authing'
    get    '/oidc/callback', to: 'sessions#oidc'
    post   '/login',   to: 'sessions#create'
    delete '/logout',  to: 'sessions#destroy'
    get    '/logout',  to: 'sessions#destroy'

    # errors
    get '/errors/not-found', to: 'errors#not_found'
    get '/errors/unauthorized', to: 'errors#unauthorized'
  end
end
