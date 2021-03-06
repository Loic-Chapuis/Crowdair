Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users
  root to: 'pages#home'
  get 'ranking', to: 'pages#ranking'
  resources :events do
    resources :transactions, only: [:new, :create, :edit, :update, :destroy]
    patch 'transactions/:id/buy', to: 'transactions#buy', as: :transaction_buy
  end
  resources :users
  resources :offers

  post 'events/:id/archive/:outcome', to: 'events#archive', as: :event_archive
end
