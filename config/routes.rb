Rails.application.routes.draw do
  resources :api_keys
  resources :models
  resources :lexicon_groups do
    resources :lexicons do
      collection do
        post 'upload'
      end
    end
    collection do 
      post 'load_samples'
    end
  end
  root to: 'home#index'
  get 'home/index'

  get '/sessions/:session_str', to: 'users#sessions'
  resources :lexicons
  resources :entity_types
  resources :documents do 
    collection do 
      get 'check'
    end
    member do
      get 'verify'
      get 'partial'
      post 'delete_all_annotations'
      post 'done'
      post 'curatable'
      get 'reorder'
    end
    resources :annotations 
  end
  resources :tasks
  resources :collections do
    collection do
      get 'partial'
      post 'load_samples'
    end
    resources :tasks do
      collection do
        get 'partial'
      end
    end
    resources :documents
    resources :entity_types do
      collection do
        post 'import_default_color'
      end
    end
    member do
      get 'download'
      post 'empty'
      post 'done_all'
      post 'delete_all_annotations'
      get 'reorder'
    end
  end
  
  devise_for :users, path: 'account', controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  resources :users do
    collection do 
      post 'sendmail'
      post 'generate'
    end
    resources :collections do
      collection do
        get 'partial'
        post 'load_samples'
      end
      resources :tasks do
        collection do
          get 'partial'
        end
      end
      resources :documents
      resources :entity_types
      member do
        get 'download'
        post 'empty'
        post 'done_all'
        post 'delete_all_annotations'
      end
    end
  end
  # devise_for :users, :controllers => { registrations: 'registrations' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
