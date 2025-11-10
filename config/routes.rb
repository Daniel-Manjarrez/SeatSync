SeatSync::Application.routes.draw do
  resources :receipts
  
  # Dashboard route
  get 'dashboard', to: 'dashboard#index'
  
  # Ingredients route
  get 'ingredients', to: 'ingredients#index'
  # Items (recipes) - allow creating new menu items with recipes
  resources :items, only: [:create, :update, :destroy]
  
  # Add new routes here

  root to: redirect('/dashboard')
end
