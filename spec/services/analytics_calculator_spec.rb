require 'rails_helper'

RSpec.describe AnalyticsCalculator, type: :service do
  let!(:item1) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees') }
  let!(:item2) { Item.create!(name: 'Fries', price: 5.0, category: 'Sides') }
  let!(:item3) { Item.create!(name: 'Soda', price: 3.0, category: 'Beverages') }
  
  let!(:receipt1) do
    Receipt.create!(
      receipt_date: Date.today - 1.day,
      receipt_time: '12:30',
      total: 15.0
    ).tap do |r|
      r.receipt_items.create!(item: item1, quantity: 1)
      r.receipt_items.create!(item: item2, quantity: 1)
    end
  end
  
  let!(:receipt2) do
    Receipt.create!(
      receipt_date: Date.today,
      receipt_time: '18:45',
      total: 20.0
    ).tap do |r|
      r.receipt_items.create!(item: item1, quantity: 2)
    end
  end
  
  let(:receipts) { [receipt1, receipt2] }
  let(:calculator) { AnalyticsCalculator.new(receipts) }

  describe '#total_orders' do
    it 'counts total number of orders' do
      expect(calculator.total_orders).to eq(2)
    end

    it 'returns 0 for no orders' do
      calc = AnalyticsCalculator.new([])
      expect(calc.total_orders).to eq(0)
    end
  end

  describe '#average_order_size' do
    it 'calculates average items per order' do
      # Receipt1: 1 burger + 1 fries = 2 items
      # Receipt2: 2 burgers = 2 items
      # Average: 4 items / 2 orders = 2.0
      expect(calculator.average_order_size).to eq(2.0)
    end

    it 'returns 0 for no orders' do
      calc = AnalyticsCalculator.new([])
      expect(calc.average_order_size).to eq(0)
    end
  end

  describe '#average_spend' do
    it 'calculates average revenue per order' do
      # Receipt1: $15, Receipt2: $20
      # Average: $35 / 2 = $17.50
      expect(calculator.average_spend).to eq(17.5)
    end

    it 'returns 0 for no orders' do
      calc = AnalyticsCalculator.new([])
      expect(calc.average_spend).to eq(0)
    end
  end

  describe '#occupancy_rate' do
    it 'calculates occupancy based on orders' do
      rate = calculator.occupancy_rate(20, 12)
      expect(rate).to be >= 0
      expect(rate).to be <= 100
    end

    it 'returns 0 for no orders' do
      calc = AnalyticsCalculator.new([])
      expect(calc.occupancy_rate).to eq(0)
    end
  end

  describe '#revenue_by_category' do
    it 'groups revenue by item category' do
      result = calculator.revenue_by_category
      
      expect(result['Entrees']).to eq(30.0)  # 1×$10 + 2×$10
      expect(result['Sides']).to eq(5.0)     # 1×$5
    end

    it 'handles receipts with no items' do
      empty_receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '10:00',
        total: 0
      )
      calc = AnalyticsCalculator.new([empty_receipt])
      
      result = calc.revenue_by_category
      expect(result).to eq({})
    end
  end

  describe '#most_popular_items' do
    it 'returns items ordered by quantity' do
      result = calculator.most_popular_items(10)
      
      expect(result.first[:name]).to eq('Burger')
      expect(result.first[:count]).to eq(3)  # 1 + 2
    end

    it 'limits results to specified number' do
      result = calculator.most_popular_items(1)
      
      expect(result.length).to eq(1)
    end
  end

  describe '#least_popular_items' do
    it 'returns items ordered by quantity ascending' do
      result = calculator.least_popular_items(10)
      
      expect(result.last[:name]).to eq('Burger')
      expect(result.first[:name]).to eq('Fries')
    end
  end

  describe '#product_performance' do
    it 'returns items by revenue' do
      result = calculator.product_performance(10)
      
      expect(result.first[:name]).to eq('Burger')
      expect(result.first[:amount]).to eq(30.0)
    end

    it 'limits results' do
      result = calculator.product_performance(1)
      
      expect(result.length).to eq(1)
    end
  end

  describe '#revenue_by_day_of_week' do
    it 'groups revenue by day names' do
      result = calculator.revenue_by_day_of_week
      
      expect(result.keys).to include('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
      expect(result.values.sum).to eq(35.0)
    end
  end

  describe '#revenue_by_meal_period' do
    it 'groups revenue by meal periods' do
      result = calculator.revenue_by_meal_period
      
      expect(result).to have_key('Breakfast (6-11 AM)')
      expect(result).to have_key('Lunch (11 AM-3 PM)')
      expect(result).to have_key('Dinner (3-9 PM)')
      expect(result).to have_key('Late Night (9 PM+)')
    end

    it 'categorizes receipts correctly' do
      result = calculator.revenue_by_meal_period
      
      # receipt1 at 12:30 -> Lunch
      # receipt2 at 18:45 -> Dinner
      expect(result['Lunch (11 AM-3 PM)']).to eq(15.0)
      expect(result['Dinner (3-9 PM)']).to eq(20.0)
    end
  end

  describe '#orders_by_hour' do
    it 'counts orders by hour' do
      result = calculator.orders_by_hour
      
      expect(result).to be_a(Hash)
      expect(result.values.sum).to eq(2)
    end

    it 'formats hour labels correctly' do
      result = calculator.orders_by_hour
      
      expect(result.keys).to include('12 PM')
      expect(result.keys).not_to include('24 PM')
    end
  end

  describe '#week_over_week_growth' do
    it 'calculates growth percentage' do
      result = calculator.week_over_week_growth
      
      expect(result).to be_a(Numeric)
    end

    it 'returns 0 when no prior week data' do
      recent_receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        total: 10.0
      )
      calc = AnalyticsCalculator.new([recent_receipt])
      
      expect(calc.week_over_week_growth).to eq(0)
    end
  end

  describe '#month_over_month_growth' do
    it 'calculates growth percentage' do
      result = calculator.month_over_month_growth
      
      expect(result).to be_a(Numeric)
    end

    it 'returns 0 when no prior month data' do
      calc = AnalyticsCalculator.new([receipt1])
      
      expect(calc.month_over_month_growth).to eq(0)
    end
  end

  describe '#weekday_vs_weekend_performance' do
    it 'compares weekday and weekend performance' do
      result = calculator.weekday_vs_weekend_performance
      
      expect(result).to have_key(:weekday)
      expect(result).to have_key(:weekend)
      expect(result[:weekday]).to have_key(:revenue)
      expect(result[:weekday]).to have_key(:orders)
      expect(result[:weekday]).to have_key(:avg_per_order)
    end

    it 'handles weekend-only receipts' do
      # Create receipt on Saturday (wday = 6)
      saturday = Date.today
      saturday += 1 until saturday.wday == 6
      
      weekend_receipt = Receipt.create!(
        receipt_date: saturday,
        receipt_time: '12:00',
        total: 25.0
      )
      
      calc = AnalyticsCalculator.new([weekend_receipt])
      result = calc.weekday_vs_weekend_performance
      
      expect(result[:weekend][:orders]).to eq(1)
      expect(result[:weekday][:orders]).to eq(0)
    end
  end

  describe '#price_point_distribution' do
    it 'groups orders by price ranges' do
      result = calculator.price_point_distribution
      
      expect(result).to have_key('$0-10')
      expect(result).to have_key('$10-20')
      expect(result).to have_key('$20-30')
    end

    it 'counts orders in correct ranges' do
      result = calculator.price_point_distribution
      
      # receipt1: $15 -> $10-20 range
      # receipt2: $20 -> $10-20 range
      expect(result['$10-20']).to eq(2)
    end
  end

  describe '#average_orders_per_hour' do
    it 'calculates orders per operating hour' do
      result = calculator.average_orders_per_hour
      
      expect(result).to be >= 0
    end

    it 'returns 0 for no receipts' do
      calc = AnalyticsCalculator.new([])
      
      expect(calc.average_orders_per_hour).to eq(0)
    end
  end

  describe '#time_between_orders' do
    it 'calculates average time between orders' do
      result = calculator.time_between_orders
      
      expect(result).to be >= 0
    end

    it 'returns 0 for single order' do
      calc = AnalyticsCalculator.new([receipt1])
      
      expect(calc.time_between_orders).to eq(0)
    end

    it 'returns 0 for no orders' do
      calc = AnalyticsCalculator.new([])
      
      expect(calc.time_between_orders).to eq(0)
    end
  end

  describe '#daily_revenue' do
    it 'returns revenue grouped by days' do
      result = calculator.daily_revenue(30)
      
      expect(result).to be_a(Hash)
    end

    it 'returns empty hash when no receipts in range' do
      old_receipt = Receipt.create!(
        receipt_date: Date.today - 60.days,
        receipt_time: '12:00',
        total: 10.0
      )
      calc = AnalyticsCalculator.new([old_receipt])
      
      result = calc.daily_revenue(30)
      expect(result).to eq({})
    end
  end

  describe '#orders_by_fifteen_min_intervals' do
    it 'groups orders by 15-minute intervals' do
      result = calculator.orders_by_fifteen_min_intervals(11, 15)
      
      expect(result).to be_a(Hash)
      expect(result.keys).not_to be_empty
    end
  end

  describe '#item_attachment_rate' do
    it 'calculates attachment rates for item pairs' do
      result = calculator.item_attachment_rate([['Burger', 'Fries']])
      
      expect(result).to be_an(Array)
    end

    it 'handles empty pairs' do
      result = calculator.item_attachment_rate([])
      
      expect(result).to eq([])
    end
  end

  describe 'private helper methods' do
    describe '#parse_hour' do
      it 'parses 24-hour format' do
        result = calculator.send(:parse_hour, '14:30')
        expect(result).to eq(14)
      end

      it 'parses 12-hour format with PM' do
        result = calculator.send(:parse_hour, '2:30 PM')
        expect(result).to eq(14)
      end

      it 'parses 12-hour format with AM' do
        result = calculator.send(:parse_hour, '10:30 AM')
        expect(result).to eq(10)
      end

      it 'handles 12 PM' do
        result = calculator.send(:parse_hour, '12:00 PM')
        expect(result).to eq(12)
      end

      it 'handles 12 AM' do
        result = calculator.send(:parse_hour, '12:00 AM')
        expect(result).to eq(0)
      end

      it 'returns 0 for invalid format' do
        result = calculator.send(:parse_hour, 'invalid')
        expect(result).to eq(0)
      end
    end

    describe '#parse_minute' do
      it 'parses minutes correctly' do
        result = calculator.send(:parse_minute, '14:45')
        expect(result).to eq(45)
      end

      it 'returns 0 for invalid format' do
        result = calculator.send(:parse_minute, 'invalid')
        expect(result).to eq(0)
      end
    end

    describe '#calculate_receipt_total' do
      it 'uses receipt total when available' do
        total = calculator.send(:calculate_receipt_total, receipt1)
        expect(total).to eq(15.0)
      end

      it 'calculates from items when total not available' do
        receipt_without_total = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00'
        )
        receipt_without_total.receipt_items.create!(item: item1, quantity: 2)
        
        total = calculator.send(:calculate_receipt_total, receipt_without_total)
        expect(total).to eq(20.0)
      end
    end

    describe '#format_time' do
      it 'formats hour and minute correctly' do
        result = calculator.send(:format_time, 14, 30)
        expect(result).to eq('2:30')
      end

      it 'handles midnight' do
        result = calculator.send(:format_time, 0, 0)
        expect(result).to eq('12:00')
      end

      it 'pads minutes' do
        result = calculator.send(:format_time, 10, 5)
        expect(result).to eq('10:05')
      end
    end
  end
end

