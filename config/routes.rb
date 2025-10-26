Rottenpotatoes::Application.routes.draw do
  resources :receipts
  resources :movies
  # Add new routes here

  root to: redirect('/receipts')
end
