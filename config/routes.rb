# frozen_string_literal: true
QaServer::Engine.routes.draw do
  # Downloads controller route
  resources :homepage, only: 'index'

  # Route the home page as the root
  root to: 'homepage#index'

  resources :usage, only: 'index'
  resources :check_status, only: 'index'
  resources :monitor_status, only: 'index'
  resources :authority_list, only: 'index'
end
