require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  describe 'GET #index' do
    let!(:item) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees') }
    let!(:receipt) do
      Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        total: 10.0
      ).tap do |r|
        r.receipt_items.create!(item: item, quantity: 1)
      end
    end

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'loads overview tab by default' do
      get :index
      expect(assigns(:total_orders)).to be_present
      expect(assigns(:occupancy_rate)).to be_present
    end

    it 'loads revenue tab when specified' do
      get :index, params: { tab: 'revenue' }
      expect(assigns(:daily_revenue)).to be_present
      expect(assigns(:revenue_by_category)).to be_present
    end

    it 'loads menu tab when specified' do
      get :index, params: { tab: 'menu' }
      expect(assigns(:most_popular_items)).to be_present
      expect(assigns(:product_data)).to be_present
    end

    it 'loads timing tab when specified' do
      get :index, params: { tab: 'timing' }
      expect(assigns(:timing_data)).to be_present
      expect(assigns(:fifteen_min_intervals)).to be_present
    end

    it 'sets growth metrics' do
      get :index
      expect(assigns(:week_over_week_growth)).to be_a(Numeric)
      expect(assigns(:month_over_month_growth)).to be_a(Numeric)
    end
  end
end

