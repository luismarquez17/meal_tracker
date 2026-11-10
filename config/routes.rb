Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  get "dashboard", to: "dashboard#index"
  get "analytics", to: "analytics#index"

  # Autenticación y Registro
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Google OAuth Oficial
  match "/auth/:provider/callback", to: "sessions#omniauth", via: %i[get post]
  get "/auth/failure", to: "sessions#failure"

  # Registros de Comidas
  resources :meal_logs do
    collection do
      get :by_date
    end
    resources :meal_reactions, only: %i[create destroy]
  end

  # Resumen Semanal Gamificado Estilo Wrapped
  resource :weekly_summary, only: %i[show]

  # Modo Pareja / Familia Compartida (Hogar)
  resource :household, only: %i[show new create] do
    post :join
    delete :leave
    patch :update_goal
    post :assign_turn
  end

  # Ajustes de Usuario
  resource :setting, only: %i[show edit update]

  # Área de Suscripciones para Clientes ($2.00/mes)
  resource :subscription, only: %i[show] do
    post :create_payment
  end

  # Perfil de Usuario
  resource :profile, only: %i[show edit update] do
    get :change_password
    patch :update_password
  end
  # Área Super Admin (Solo luismarquezocando2006@gmail.com)
  namespace :admin do
    root to: "dashboard#index", as: :dashboard
    
    resources :users, only: %i[index show] do
      member do
        post :extend_subscription
        post :toggle_admin
      end
    end

    resources :payments, only: %i[index] do
      member do
        post :approve
        post :reject
      end
    end

    resource :payment_setting, only: %i[edit update] do
      post :sync_bcv
    end
  end
end
