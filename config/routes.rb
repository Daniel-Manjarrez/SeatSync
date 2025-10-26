SeatSync::Application.routes.draw do
  resources :receipts
  # Add new routes here

  root to: redirect('/receipts')
end
