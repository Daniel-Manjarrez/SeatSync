# Consolidated Step Definitions

Given('the following test receipts exist:') do |table|
  Receipt.destroy_all

  # Create test items if they don't exist
  test_items = {
    'Coffee' => { price: 3.99, category: 'Beverages' },
    'Croissant' => { price: 4.99, category: 'Desserts' },
    'Burger' => { price: 14.99, category: 'Entrees' },
    'Fries' => { price: 3.99, category: 'Sides' },
    'Soda' => { price: 2.99, category: 'Beverages' },
    'Pizza' => { price: 16.99, category: 'Entrees' },
    'Steak' => { price: 29.99, category: 'Entrees' },
    'Salad' => { price: 9.99, category: 'Appetizers' }
  }

  test_items.each do |name, attrs|
    Item.find_or_create_by!(name: name) do |item|
      item.price = attrs[:price]
      item.category = attrs[:category]
    end
  end

  table.hashes.each do |row|
    item_names = row['items'].split(',').map(&:strip)
    receipt = Receipt.create!(
      receipt_date: Date.parse(row['date']),
      receipt_time: row['time'],
      order_items: item_names
    )

    # Create receipt_items for each item
    item_names.each do |item_name|
      item = Item.find_by(name: item_name)
      receipt.receipt_items.create!(item: item, quantity: 1) if item
    end
  end
end

When('I run all analytics calculations') do
  @menu_prices = {
    'Coffee' => 3.99, 'Croissant' => 4.99,
    'Burger' => 14.99, 'Fries' => 3.99, 'Soda' => 2.99,
    'Pizza' => 16.99, 'Steak' => 29.99, 'Salad' => 9.99
  }
  
  @calculator = AnalyticsCalculator.new(Receipt.all, @menu_prices)
  
  # Execute all methods to ensure coverage
  @total = @calculator.total_orders
  @avg_size = @calculator.average_order_size
  @avg_spend = @calculator.average_spend
  @occupancy = @calculator.occupancy_rate(20, 12)
  @daily_rev = @calculator.daily_revenue(30)
  @weekly_rev = @calculator.weekly_revenue(8)
  @monthly_rev = @calculator.monthly_revenue(12)
  @rev_by_day = @calculator.revenue_by_day_of_week
  @rev_by_period = @calculator.revenue_by_meal_period
  @rev_by_cat = @calculator.revenue_by_category
  @avg_check = @calculator.average_check_by_time_of_day
  @popular = @calculator.most_popular_items(10)
  @unpopular = @calculator.least_popular_items(10)
  @product_perf = @calculator.product_performance(10)
  @attachments = @calculator.item_attachment_rate([['Burger', 'Fries'], ['Pizza', 'Soda']])
  @by_hour = @calculator.orders_by_hour
  @intervals = @calculator.orders_by_fifteen_min_intervals(11, 15)
  @avg_per_hour = @calculator.average_orders_per_hour
  @time_between = @calculator.time_between_orders
  @price_dist = @calculator.price_point_distribution
  @wow = @calculator.week_over_week_growth
  @mom = @calculator.month_over_month_growth
  @weekday_weekend = @calculator.weekday_vs_weekend_performance
end

Then('total orders should equal {int}') do |count|
  expect(@total).to eq(count)
end

Then('average order size should be calculated') do
  expect(@avg_size).to be > 0
end

Then('average spend should be calculated') do
  expect(@avg_spend).to be > 0
end

Then('most popular item should be {string}') do |item|
  expect(@popular.first[:name]).to eq(item)
end

Then('revenue by day of week should have all days') do
  expect(@rev_by_day.keys).to include('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
end

Then('revenue by meal period should have all periods') do
  expect(@rev_by_period.keys).to include('Breakfast (6-11 AM)', 'Lunch (11 AM-3 PM)', 'Dinner (3-9 PM)', 'Late Night (9 PM+)')
end

Then('orders by hour should be grouped') do
  expect(@by_hour).to be_a(Hash)
  expect(@by_hour.values.sum).to be > 0
end

Then('weekday vs weekend should be compared') do
  expect(@weekday_weekend).to have_key(:weekday)
  expect(@weekday_weekend).to have_key(:weekend)
end

Then('growth metrics should be calculated') do
  expect(@wow).to be_a(Numeric)
  expect(@mom).to be_a(Numeric)
end

Then('price distribution should be categorized') do
  expect(@price_dist.keys).to include('$0-10', '$10-20', '$20-30', '$30-40', '$40-50', '$50+')
end

Then('product performance should be ranked') do
  expect(@product_perf).to be_an(Array)
  expect(@product_perf).not_to be_empty
end

Then('item pairing should be analyzed') do
  expect(@attachments).to be_an(Array)
  expect(@attachments.first[:rate]).to be_between(0, 100)
end

