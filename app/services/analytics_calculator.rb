# app/services/analytics_calculator.rb
# Service to calculate all restaurant metrics from receipt data
# 
# Receipt data structure expected:
# - receipt_date: Date
# - receipt_time: String (e.g., "12:00")
# - order_items: Array of strings (e.g., ["Caesar Salad", "Garlic Bread"])
#
# Menu data structure expected:
# - Hash of item_name => price (e.g., {"Caesar Salad" => 12.99, "Garlic Bread" => 4.99})

class AnalyticsCalculator
  
  def initialize(receipts, menu_prices = {})
    @receipts = receipts
    @menu_prices = menu_prices
  end
  
  # ============================================
  # TOP LEVEL METRICS
  # ============================================
  
  def total_orders
    @receipts.count
  end
  
  def average_order_size
    return 0 if @receipts.empty?
    total_items = @receipts.sum { |r| r.receipt_items.sum(:quantity) }
    (total_items.to_f / @receipts.count).round(2)
  end
  
  def average_spend
    return 0 if @receipts.empty?
    total_revenue = calculate_total_revenue
    (total_revenue / @receipts.count).round(2)
  end
  
  def occupancy_rate(total_tables = 20, operating_hours = 12)
    # Calculate based on orders per table capacity
    # Assumes each order occupies a table for ~1 hour
    return 0 if @receipts.empty?
    
    orders_per_day = @receipts.count.to_f / unique_days.count
    max_capacity = total_tables * operating_hours
    ((orders_per_day / max_capacity) * 100).round(2)
  end
  
  # ============================================
  # REVENUE METRICS
  # ============================================
  
  def daily_revenue(days = 30)
    start_date = Date.today - days.days
    
    grouped = @receipts
      .select { |r| r.receipt_date >= start_date }
      .group_by { |r| r.receipt_date.strftime('%b %d') }
      .transform_values { |receipts| calculate_revenue_for_receipts(receipts) }
    
    # Return as-is if grouping worked
    return grouped if grouped.any?
    
    # Otherwise return empty hash
    {}
  end
  
  def weekly_revenue(weeks = 8)
    grouped = @receipts.group_by { |r| r.receipt_date.cweek }
    
    grouped.map.with_index do |(week, receipts), i|
      ["Week #{i + 1}", calculate_revenue_for_receipts(receipts)]
    end.to_h
  end
  
  def monthly_revenue(months = 12)
    @receipts
      .group_by { |r| r.receipt_date.strftime('%b %Y') }
      .transform_values { |receipts| calculate_revenue_for_receipts(receipts) }
      .sort_by { |month, _| Date.parse("01 #{month}") }
      .to_h
  end
  
  def revenue_by_day_of_week
    days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
    
    grouped = @receipts.group_by { |r| r.receipt_date.strftime('%A') }
    
    days.map do |day|
      revenue = grouped[day] ? calculate_revenue_for_receipts(grouped[day]) : 0
      [day, revenue]
    end.to_h
  end
  
  def revenue_by_meal_period
    periods = {
      'Breakfast (6-11 AM)' => (6...11),
      'Lunch (11 AM-3 PM)' => (11...15),
      'Dinner (3-9 PM)' => (15...21),
      'Late Night (9 PM+)' => (21...24)
    }
    
    periods.map do |name, hour_range|
      receipts_in_period = @receipts.select do |r|
        hour = parse_hour(r.receipt_time)
        hour_range.include?(hour)
      end
      [name, calculate_revenue_for_receipts(receipts_in_period)]
    end.to_h
  end
  
  def revenue_by_category
    category_revenue = Hash.new(0)
    
    @receipts.each do |receipt|
      receipt.receipt_items.includes(:item).each do |receipt_item|
        category = receipt_item.item.category || "Other"
        revenue = receipt_item.item.price * receipt_item.quantity
        category_revenue[category] += revenue
      end
    end
    
    category_revenue
  end
  
  def average_check_by_time_of_day
    hours = (11..22).to_a # 11 AM to 10 PM
    
    hours.map do |hour|
      receipts_at_hour = @receipts.select do |r|
        parse_hour(r.receipt_time) == hour
      end
      
      avg = receipts_at_hour.empty? ? 0 : calculate_revenue_for_receipts(receipts_at_hour) / receipts_at_hour.count
      
      label = hour <= 12 ? "#{hour} AM" : "#{hour - 12} PM"
      label = "12 PM" if hour == 12
      
      [label, avg.round(2)]
    end.to_h
  end
  
  # ============================================
  # GROWTH METRICS
  # ============================================
  
  def week_over_week_growth
    this_week = receipts_in_week(0)
    last_week = receipts_in_week(1)
    
    return 0 if last_week.empty?
  
    this_revenue = calculate_revenue_for_receipts(this_week)
    last_revenue = calculate_revenue_for_receipts(last_week)
  
    return 0 if last_revenue == 0
  
    ((this_revenue - last_revenue) / last_revenue.to_f * 100).round(2)
  end
  
  def month_over_month_growth
    this_month = receipts_in_month(0)
    last_month = receipts_in_month(1)

    return 0 if last_month.empty?

    this_revenue = calculate_revenue_for_receipts(this_month)
    last_revenue = calculate_revenue_for_receipts(last_month)

    return 0 if last_revenue == 0

    ((this_revenue - last_revenue) / last_revenue * 100).round(2)
  end
  
  def weekday_vs_weekend_performance
    weekday = @receipts.select { |r| (1..5).include?(r.receipt_date.wday) }
    weekend = @receipts.select { |r| [0, 6].include?(r.receipt_date.wday) }
    
    {
      weekday: {
        revenue: calculate_revenue_for_receipts(weekday),
        orders: weekday.count,
        avg_per_order: weekday.empty? ? 0 : (calculate_revenue_for_receipts(weekday) / weekday.count).round(2)
      },
      weekend: {
        revenue: calculate_revenue_for_receipts(weekend),
        orders: weekend.count,
        avg_per_order: weekend.empty? ? 0 : (calculate_revenue_for_receipts(weekend) / weekend.count).round(2)
      }
    }
  end
  
  # ============================================
  # MENU PERFORMANCE METRICS
  # ============================================
  
  def most_popular_items(limit = 10)
    item_counts = Hash.new(0)
    
    @receipts.each do |receipt|
      receipt.receipt_items.includes(:item).each do |receipt_item|
        item_counts[receipt_item.item.name] += receipt_item.quantity
      end
    end
    
    item_counts
      .sort_by { |_, count| -count }
      .first(limit)
      .map { |name, count| { name: name, count: count } }
  end
  
  def least_popular_items(limit = 10)
    item_counts = Hash.new(0)
    
    @receipts.each do |receipt|
      receipt.receipt_items.includes(:item).each do |receipt_item|
        item_counts[receipt_item.item.name] += receipt_item.quantity
      end
    end
    
    item_counts
      .sort_by { |_, count| count }
      .first(limit)
      .map { |name, count| { name: name, count: count } }
  end
  
  def item_attachment_rate(item_pairs = [])
    # item_pairs: Array of [item_a, item_b] pairs to analyze
    # Example: [["Burger", "Fries"], ["Pizza", "Soda"]]
    
    item_pairs.map do |item_a, item_b|
      item_a_receipts = @receipts.select do |r|
        r.receipt_items.joins(:item).where(items: { name: item_a }).exists?
      end
      
      both_items = item_a_receipts.select do |r|
        r.receipt_items.joins(:item).where(items: { name: item_b }).exists?
      end
      
      rate = item_a_receipts.empty? ? 0 : ((both_items.count.to_f / item_a_receipts.count) * 100).round(0)
      
      { item_a: item_a, item_b: item_b, rate: rate }
    end
  end
  
  def product_performance(limit = 10)
    item_revenue = Hash.new(0)
    
    @receipts.each do |receipt|
      receipt.receipt_items.includes(:item).each do |receipt_item|
        revenue = receipt_item.item.price * receipt_item.quantity
        item_revenue[receipt_item.item.name] += revenue
      end
    end
    
    item_revenue
      .sort_by { |_, revenue| -revenue }
      .first(limit)
      .map { |name, amount| { name: name, amount: amount.round(2) } }
  end
  
  # ============================================
  # TIMING METRICS
  # ============================================
  
  def orders_by_hour
    hours = (11..22).to_a # 11 AM to 10 PM
    
    hours.map do |hour|
      count = @receipts.count { |r| parse_hour(r.receipt_time) == hour }
      
      label = hour <= 12 ? "#{hour} AM" : "#{hour - 12} PM"
      label = "12 PM" if hour == 12
      
      [label, count]
    end.to_h
  end
  
  def orders_by_fifteen_min_intervals(start_hour = 11, end_hour = 15)
    # Default: lunch rush 11 AM - 3 PM
    intervals = []
    
    (start_hour...end_hour).each do |hour|
      [0, 15, 30, 45].each do |minute|
        time_label = format_time(hour, minute)
        count = @receipts.count do |r|
          receipt_hour = parse_hour(r.receipt_time)
          receipt_minute = parse_minute(r.receipt_time)
          receipt_hour == hour && receipt_minute >= minute && receipt_minute < minute + 15
        end
        intervals << [time_label, count]
      end
    end
    
    intervals.to_h
  end
  
  def average_orders_per_hour
    return 0 if @receipts.empty?
    
    operating_hours = unique_hours.count
    return 0 if operating_hours.zero?
    
    (@receipts.count.to_f / operating_hours).round(2)
  end
  
  def time_between_orders
    return 0 if @receipts.count < 2

    sorted = @receipts.sort_by { |r| DateTime.parse("#{r.receipt_date} #{r.receipt_time}") }
    time_diffs = []

    sorted.each_cons(2) do |receipt1, receipt2|
      time1 = DateTime.parse("#{receipt1.receipt_date} #{receipt1.receipt_time}")
      time2 = DateTime.parse("#{receipt2.receipt_date} #{receipt2.receipt_time}")
      diff_minutes = ((time2 - time1) * 24 * 60).to_f
      time_diffs << diff_minutes if diff_minutes > 0
    end

    return 0 if time_diffs.empty?
    (time_diffs.sum / time_diffs.count.to_f).round(2)
  end
  
  # ============================================
  # PRICING METRICS
  # ============================================
  
  def price_point_distribution
    ranges = {
      '$0-10' => (0..10),
      '$10-20' => (10..20),
      '$20-30' => (20..30),
      '$30-40' => (30..40),
      '$40-50' => (40..50),
      '$50+' => (50..Float::INFINITY)
    }
    
    ranges.map do |label, range|
      count = @receipts.count do |receipt|
        total = calculate_receipt_total(receipt)
        range.include?(total)
      end
      [label, count]
    end.to_h
  end
  
  # ============================================
  # HELPER METHODS
  # ============================================
  
  private
  
  def calculate_total_revenue
    @receipts.sum { |receipt| calculate_receipt_total(receipt) }
  end
  
  def calculate_revenue_for_receipts(receipts)
    receipts.sum { |receipt| calculate_receipt_total(receipt) }
  end
  
  def calculate_receipt_total(receipt)
    # Use the actual total from receipt if available, otherwise calculate
    return receipt.total if receipt.total.present? && receipt.total > 0
    
    # Calculate from receipt items
    receipt.receipt_items.includes(:item).sum do |receipt_item|
      receipt_item.item.price * receipt_item.quantity
    end
  end
  
  def parse_hour(time_string)
    # Handles formats: "12:00", "12:00 PM", "1:30 PM", etc.
    time_string = time_string.strip
    
    # Try parsing with AM/PM
    if time_string.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i)
      hour = $1.to_i
      period = $3.upcase
      
      if period == 'PM' && hour != 12
        hour += 12
      elsif period == 'AM' && hour == 12
        hour = 0
      end
      
      return hour
    end
    
    # Try parsing 24-hour format
    if time_string.match(/(\d{1,2}):(\d{2})/)
      return $1.to_i
    end
    
    0
  end
  
  def parse_minute(time_string)
    time_string = time_string.strip
    
    if time_string.match(/\d{1,2}:(\d{2})/)
      return $1.to_i
    end
    
    0
  end
  
  def format_time(hour, minute)
    period = hour < 12 ? 'AM' : 'PM'
    display_hour = hour > 12 ? hour - 12 : hour
    display_hour = 12 if hour == 0 || hour == 12
    
    "#{display_hour}:#{minute.to_s.rjust(2, '0')}"
  end
  
  def unique_days
    @receipts.map(&:receipt_date).uniq
  end
  
  def unique_hours
    @receipts.map { |r| parse_hour(r.receipt_time) }.uniq
  end
  
  def receipts_in_week(weeks_ago)
    start_date = Date.today - (weeks_ago + 1).weeks
    end_date = Date.today - weeks_ago.weeks
    
    @receipts.select { |r| r.receipt_date >= start_date && r.receipt_date < end_date }
  end
  
  def receipts_in_month(months_ago)
    start_date = Date.today - (months_ago + 1).months
    end_date = Date.today - months_ago.months
    
    @receipts.select { |r| r.receipt_date >= start_date && r.receipt_date < end_date }
  end
end

# ============================================
# USAGE EXAMPLE (When Database is Ready)
# ============================================
#
# # In dashboard_controller.rb:
# def index
#   receipts = Receipt.all
#   
#   menu_prices = {
#     "Caesar Salad" => 12.99,
#     "Garlic Bread" => 4.99,
#     "Burger" => 14.99,
#     "Fries" => 3.99,
#     # ... more items
#   }
#   
#   calculator = AnalyticsCalculator.new(receipts, menu_prices)
#   
#   # Get all metrics
#   @total_orders = calculator.total_orders
#   @average_order_size = calculator.average_order_size
#   @average_spend = calculator.average_spend
#   @occupancy_rate = calculator.occupancy_rate
#   
#   @daily_revenue = calculator.daily_revenue(30)
#   @weekly_revenue = calculator.weekly_revenue(8)
#   @monthly_revenue = calculator.monthly_revenue(12)
#   
#   @revenue_by_day = calculator.revenue_by_day_of_week
#   @revenue_by_meal_period = calculator.revenue_by_meal_period
#   
#   @most_popular_items = calculator.most_popular_items(10)
#   @least_popular_items = calculator.least_popular_items(10)
#   
#   @timing_data = calculator.orders_by_hour
#   @fifteen_min_intervals = calculator.orders_by_fifteen_min_intervals
#   
#   @week_over_week_growth = calculator.week_over_week_growth
#   @month_over_month_growth = calculator.month_over_month_growth
#   
#   # ... etc
# end

