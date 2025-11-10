class DashboardController < ApplicationController
  layout 'dashboard'

  def index
    # Load receipts with associations for better performance
    receipts = Receipt.includes(receipt_items: :item).all
    calculator = AnalyticsCalculator.new(receipts)

    # Determine current tab
    current_tab = params[:tab] || 'overview'

    # === ALWAYS NEEDED (for header and empty state) ===
    @total_orders = calculator.total_orders
    @week_over_week_growth = calculator.week_over_week_growth
    @month_over_month_growth = calculator.month_over_month_growth

    # === LOAD ONLY WHAT'S NEEDED FOR CURRENT TAB ===
    case current_tab
    when 'overview'
      load_overview_metrics(calculator)
    when 'revenue'
      load_revenue_metrics(calculator)
    when 'menu'
      load_menu_metrics(calculator)
    when 'timing'
      load_timing_metrics(calculator)
    end
  end

  private

  def load_overview_metrics(calculator)
    # Top 4 cards
    @occupancy_rate = calculator.occupancy_rate
    @average_order_size = calculator.average_order_size
    @average_spend = calculator.average_spend

    # 4 charts
    @daily_revenue = calculator.daily_revenue(30)
    @timing_data = calculator.orders_by_hour
    @revenue_by_day = calculator.revenue_by_day_of_week
    @price_distribution = calculator.price_point_distribution
  end

  def load_revenue_metrics(calculator)
    # Revenue trends
    @daily_revenue = calculator.daily_revenue(30)
    @weekly_revenue = calculator.weekly_revenue(8)
    @monthly_revenue = calculator.monthly_revenue(12)

    # Revenue breakdowns
    @revenue_by_day = calculator.revenue_by_day_of_week
    @revenue_by_meal_period = calculator.revenue_by_meal_period
    @revenue_by_category = calculator.revenue_by_category
    @avg_check_by_time = calculator.average_check_by_time_of_day

    # Weekday vs Weekend
    weekday_weekend = calculator.weekday_vs_weekend_performance
    @weekday_revenue = weekday_weekend[:weekday][:revenue]
    @weekend_revenue = weekday_weekend[:weekend][:revenue]
    @weekday_orders = weekday_weekend[:weekday][:orders]
    @weekend_orders = weekday_weekend[:weekend][:orders]
  end

  def load_menu_metrics(calculator)
    # Popular items
    @most_popular_items = calculator.most_popular_items(10)
    @least_popular_items = calculator.least_popular_items(10)

    # Item attachments (only if we have popular items)
    if @most_popular_items.any?
      top_items = @most_popular_items.first(5).map { |i| i[:name] }
      item_pairs = top_items.combination(2).to_a.first(5)
      @item_attachments = calculator.item_attachment_rate(item_pairs)
    else
      @item_attachments = []
    end

    # Product performance
    @product_data = calculator.product_performance(10)
  end

  def load_timing_metrics(calculator)
    # Timing cards
    @average_order_size = calculator.average_order_size
    @average_items_per_order = calculator.average_order_size
    @average_orders_per_hour = calculator.average_orders_per_hour
    @time_between_orders = calculator.time_between_orders

    # Timing charts
    @timing_data = calculator.orders_by_hour
    @fifteen_min_intervals = calculator.orders_by_fifteen_min_intervals
    @revenue_by_meal_period = calculator.revenue_by_meal_period
  end
end
