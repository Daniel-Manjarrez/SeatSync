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

    it 'uses dashboard layout' do
      get :index
      expect(response).to render_template(layout: 'dashboard')
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

    describe 'load_overview_metrics' do
      before { get :index, params: { tab: 'overview' } }

      it 'loads occupancy rate' do
        expect(assigns(:occupancy_rate)).to be_a(Numeric)
      end

      it 'loads average order size' do
        expect(assigns(:average_order_size)).to be_a(Numeric)
      end

      it 'loads average spend' do
        expect(assigns(:average_spend)).to be_a(Numeric)
      end

      it 'loads daily revenue chart data' do
        expect(assigns(:daily_revenue)).to be_a(Hash)
      end

      it 'loads timing data' do
        expect(assigns(:timing_data)).to be_a(Hash)
      end

      it 'loads revenue by day' do
        expect(assigns(:revenue_by_day)).to be_a(Hash)
      end

      it 'loads price distribution' do
        expect(assigns(:price_distribution)).to be_a(Hash)
      end
    end

    describe 'load_revenue_metrics' do
      before { get :index, params: { tab: 'revenue' } }

      it 'loads daily revenue' do
        expect(assigns(:daily_revenue)).to be_a(Hash)
      end

      it 'loads weekly revenue' do
        expect(assigns(:weekly_revenue)).to be_a(Hash)
      end

      it 'loads monthly revenue' do
        expect(assigns(:monthly_revenue)).to be_a(Hash)
      end

      it 'loads revenue by day of week' do
        expect(assigns(:revenue_by_day)).to be_a(Hash)
      end

      it 'loads revenue by meal period' do
        expect(assigns(:revenue_by_meal_period)).to be_a(Hash)
      end

      it 'loads revenue by category' do
        expect(assigns(:revenue_by_category)).to be_a(Hash)
      end

      it 'loads average check by time' do
        expect(assigns(:avg_check_by_time)).to be_a(Hash)
      end

      it 'loads weekday vs weekend data' do
        expect(assigns(:weekday_revenue)).to be_a(Numeric)
        expect(assigns(:weekend_revenue)).to be_a(Numeric)
        expect(assigns(:weekday_orders)).to be_a(Integer)
        expect(assigns(:weekend_orders)).to be_a(Integer)
      end
    end

    describe 'load_menu_metrics' do
      before { get :index, params: { tab: 'menu' } }

      it 'loads most popular items' do
        expect(assigns(:most_popular_items)).to be_an(Array)
      end

      it 'loads least popular items' do
        expect(assigns(:least_popular_items)).to be_an(Array)
      end

      it 'loads product performance data' do
        expect(assigns(:product_data)).to be_an(Array)
      end

      context 'with popular items' do
        let!(:item2) { Item.create!(name: 'Fries', price: 5.0, category: 'Sides') }
        let!(:receipt2) do
          Receipt.create!(
            receipt_date: Date.today,
            receipt_time: '13:00',
            total: 5.0
          ).tap do |r|
            r.receipt_items.create!(item: item2, quantity: 1)
          end
        end

        it 'calculates item attachments' do
          get :index, params: { tab: 'menu' }
          expect(assigns(:item_attachments)).to be_an(Array)
        end
      end

      context 'without popular items' do
        before do
          Receipt.destroy_all
          ReceiptItem.destroy_all
        end

        it 'returns empty item attachments' do
          get :index, params: { tab: 'menu' }
          expect(assigns(:item_attachments)).to eq([])
        end
      end
    end

    describe 'load_timing_metrics' do
      before { get :index, params: { tab: 'timing' } }

      it 'loads average order size' do
        expect(assigns(:average_order_size)).to be_a(Numeric)
      end

      it 'loads average items per order' do
        expect(assigns(:average_items_per_order)).to be_a(Numeric)
      end

      it 'loads average orders per hour' do
        expect(assigns(:average_orders_per_hour)).to be_a(Numeric)
      end

      it 'loads time between orders' do
        expect(assigns(:time_between_orders)).to be_a(Numeric)
      end

      it 'loads timing data' do
        expect(assigns(:timing_data)).to be_a(Hash)
      end

      it 'loads fifteen minute intervals' do
        expect(assigns(:fifteen_min_intervals)).to be_a(Hash)
      end

      it 'loads revenue by meal period' do
        expect(assigns(:revenue_by_meal_period)).to be_a(Hash)
      end
    end

    context 'with no receipts' do
      before do
        Receipt.destroy_all
        ReceiptItem.destroy_all
      end

      it 'handles empty dataset gracefully' do
        get :index
        expect(response).to be_successful
        expect(assigns(:total_orders)).to eq(0)
      end
    end
  end
end

