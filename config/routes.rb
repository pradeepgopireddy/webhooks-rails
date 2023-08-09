Rails.application.routes.draw do
  resources :webhooks, only: [:create, :update, :index, :show, :destroy]
  # http://localhost:3000/webhooks/github_pull_request
  # http://localhost:3000/webhooks/stripe_request
  post '/webhooks/:source_name', to: 'webhooks#create'
  post '/notifiers/notify', to: 'notifiers#notify'
  root 'webhooks#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
