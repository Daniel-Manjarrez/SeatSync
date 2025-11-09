class DashboardController < ApplicationController
  layout 'dashboard'
  
  def index
    # Load receipts with associations for better performance
    receipts = Receipt.includes(receipt_items: :item).all
    calculator = AnalyticsCalculator.new(receipts)
    
    # === TOP METRICS (Overview) ===
    @total_orders = calculator.total_orders
    @occupancy_rate = calculator.occupancy_rate
    @average_order_size = calculator.average_order_size
    @average_spend = calculator.average_spend
    @quantity_per_customer = @average_order_size # Same as average order size
    
    # === REVENUE TRENDS ===
    @daily_revenue = calculator.daily_revenue(30)
    @weekly_revenue = calculator.weekly_revenue(8)
    @monthly_revenue = calculator.monthly_revenue(12)
    
    # === REVENUE BY DAY OF WEEK ===
    @revenue_by_day = calculator.revenue_by_day_of_week
    
    # === REVENUE BY MEAL PERIOD ===
    @revenue_by_meal_period = calculator.revenue_by_meal_period
    
    # === MOST & LEAST POPULAR ITEMS ===
    @most_popular_items = calculator.most_popular_items(10)
    @least_popular_items = calculator.least_popular_items(10)
    
    # === ITEM METRICS ===
    @average_items_per_order = calculator.average_order_size
    
    # Item Attachment Rate (analyze top items)
    top_items = @most_popular_items.first(5).map { |i| i[:name] }
    item_pairs = top_items.combination(2).to_a.first(5) # Analyze top 5 pairs
    @item_attachments = calculator.item_attachment_rate(item_pairs)
    
    # === PRICE POINT DISTRIBUTION ===
    @price_distribution = calculator.price_point_distribution
    
    # === TIMING METRICS ===
    @timing_data = calculator.orders_by_hour
    @fifteen_min_intervals = calculator.orders_by_fifteen_min_intervals
    @average_orders_per_hour = calculator.average_orders_per_hour
    
    # Weekday vs Weekend
    weekday_weekend = calculator.weekday_vs_weekend_performance
    @weekday_revenue = weekday_weekend[:weekday][:revenue]
    @weekend_revenue = weekday_weekend[:weekend][:revenue]
    @weekday_orders = weekday_weekend[:weekday][:orders]
    @weekend_orders = weekday_weekend[:weekend][:orders]
    
    @time_between_orders = calculator.time_between_orders
    
    # === REVENUE BY CATEGORY ===
    @revenue_by_category = calculator.revenue_by_category
    
    # Average Check Size by Time of Day
    @avg_check_by_time = calculator.average_check_by_time_of_day
    
    # === GROWTH METRICS ===
    @week_over_week_growth = calculator.week_over_week_growth
    @month_over_month_growth = calculator.month_over_month_growth
    
    # Product Performance for chart
    @product_data = calculator.product_performance(10)
  end
end
