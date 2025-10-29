SeatSync::Application.routes.draw do
  resources :receipts
  
  # Dashboard route
  get 'dashboard', to: 'dashboard#index'
  
  # Ingredients route
  get 'ingredients', to: 'ingredients#index'
  
  # Add new routes here

  root to: redirect('/dashboard')
end
