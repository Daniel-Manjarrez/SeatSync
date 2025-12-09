require 'rails_helper'

RSpec.describe IngredientsController, type: :controller do
  describe 'GET #index' do
    let!(:ingredient1) { Ingredient.create!(name: 'Tomato', unit: 'oz') }
    let!(:ingredient2) { Ingredient.create!(name: 'Cheese', unit: 'oz') }
    let!(:item1) { Item.create!(name: 'Pizza', price: 12.0, category: 'Entrees', recipes: { 'tomato' => 2.0, 'cheese' => 3.0 }) }
    let!(:item2) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees', recipes: { 'cheese' => 1.0 }) }

    before do
      # Create receipts with items for current month
      receipt1 = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        total: 20.0
      )
      receipt1.receipt_items.create!(item: item1, quantity: 2)

      receipt2 = Receipt.create!(
        receipt_date: Date.today - 1.day,
        receipt_time: '13:00',
        total: 10.0
      )
      receipt2.receipt_items.create!(item: item2, quantity: 1)

      # Create receipts for last month
      last_month_receipt = Receipt.create!(
        receipt_date: 1.month.ago,
        receipt_time: '14:00',
        total: 12.0
      )
      last_month_receipt.receipt_items.create!(item: item1, quantity: 1)
    end

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @ingredients with all ingredients ordered by name' do
      get :index
      expect(assigns(:ingredients)).to eq([ingredient2, ingredient1])  # Alphabetical order
    end

    it 'assigns @items with all items ordered by name' do
      get :index
      expect(assigns(:items)).to eq([item2, item1])  # Alphabetical order
    end

    it 'calculates @ingredient_usage for current month' do
      get :index
      usage = assigns(:ingredient_usage)

      # Pizza: 2 * (2 oz tomato + 3 oz cheese) = 4 oz tomato, 6 oz cheese
      # Burger: 1 * 1 oz cheese = 1 oz cheese
      expect(usage['Tomato']).to eq(4.0)
      expect(usage['Cheese']).to eq(7.0)
    end

    it 'calculates @last_month_usage for last month' do
      get :index
      usage = assigns(:last_month_usage)

      # Last month Pizza: 1 * (2 oz tomato + 3 oz cheese)
      expect(usage['Tomato']).to eq(2.0)
      expect(usage['Cheese']).to eq(3.0)
    end

    it 'ensures all ingredients exist in usage hash with zero for unused' do
      unused_ingredient = Ingredient.create!(name: 'Salt', unit: 'oz')

      get :index
      usage = assigns(:ingredient_usage)

      expect(usage).to have_key('Salt')
      expect(usage['Salt']).to eq(0)
    end

    it 'uses dashboard layout' do
      get :index
      expect(response).to render_template(layout: 'dashboard')
    end
  end
end
