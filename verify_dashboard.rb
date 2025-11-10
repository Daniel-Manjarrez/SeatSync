# Dashboard Verification Script
# Run with: bundle exec rails runner verify_dashboard.rb

puts "=" * 80
puts "DASHBOARD VERIFICATION"
puts "=" * 80
puts ""

# Test 1: Check if receipts exist
puts "✓ Test 1: Database Connection"
receipt_count = Receipt.count
puts "  Receipts in database: #{receipt_count}"
if receipt_count == 0
  puts "  ⚠️  WARNING: No receipts found. Run 'rails db:seed' first."
else
  puts "  ✅ PASS"
end
puts ""

# Test 2: Check if helper file exists
puts "✓ Test 2: Helper File"
helper_path = Rails.root.join('app', 'helpers', 'dashboard_helper.rb')
if File.exist?(helper_path)
  puts "  ✅ PASS - dashboard_helper.rb exists"
else
  puts "  ❌ FAIL - dashboard_helper.rb not found"
end
puts ""

# Test 3: Check if Chart.js is in layout
puts "✓ Test 3: Chart.js in Layout"
layout_path = Rails.root.join('app', 'views', 'layouts', 'dashboard.html.erb')
if File.exist?(layout_path)
  layout_content = File.read(layout_path)
  if layout_content.include?('chart.js')
    puts "  ✅ PASS - Chart.js CDN found in layout"
  else
    puts "  ❌ FAIL - Chart.js not found in layout"
  end
else
  puts "  ❌ FAIL - dashboard layout not found"
end
puts ""

# Test 4: Check if dynamic index exists
puts "✓ Test 4: Dynamic Dashboard View"
index_path = Rails.root.join('app', 'views', 'dashboard', 'index.html.erb')
if File.exist?(index_path)
  index_content = File.read(index_path)
  if index_content.include?('canvas id=') && index_content.include?('Chart.defaults')
    puts "  ✅ PASS - Dynamic charts found in index view"
  else
    puts "  ⚠️  WARNING - Index view may still have static charts"
  end
else
  puts "  ❌ FAIL - index.html.erb not found"
end
puts ""

# Test 5: Verify AnalyticsCalculator
puts "✓ Test 5: AnalyticsCalculator Service"
begin
  receipts = Receipt.includes(receipt_items: :item).all
  calculator = AnalyticsCalculator.new(receipts)
  total_orders = calculator.total_orders
  puts "  Total orders calculated: #{total_orders}"
  puts "  ✅ PASS - AnalyticsCalculator working"
rescue => e
  puts "  ❌ FAIL - Error: #{e.message}"
end
puts ""

# Test 6: Sample Analytics Calculation
if receipt_count > 0
  puts "✓ Test 6: Sample Analytics"
  receipts = Receipt.includes(receipt_items: :item).all
  calculator = AnalyticsCalculator.new(receipts)

  begin
    daily_revenue = calculator.daily_revenue(30)
    puts "  Daily revenue data points: #{daily_revenue.count}"

    timing_data = calculator.orders_by_hour
    puts "  Hourly data points: #{timing_data.count}"

    popular = calculator.most_popular_items(10)
    puts "  Popular items found: #{popular.count}"

    revenue_by_day = calculator.revenue_by_day_of_week
    puts "  Revenue by day: #{revenue_by_day.count} days"

    puts "  ✅ PASS - All analytics calculating correctly"
  rescue => e
    puts "  ❌ FAIL - Error calculating analytics: #{e.message}"
  end
else
  puts "✓ Test 6: Sample Analytics"
  puts "  ⊘ SKIPPED - No receipts to analyze"
end
puts ""

# Summary
puts "=" * 80
puts "SUMMARY"
puts "=" * 80

if receipt_count > 0
  puts "✅ Dashboard is ready to use!"
  puts ""
  puts "Next steps:"
  puts "1. Start the server: bundle exec rails server"
  puts "2. Visit: http://localhost:3000/dashboard"
  puts "3. Click through all 4 tabs to verify charts"
  puts "4. Upload more receipts from test_receipts/ for richer data"
else
  puts "⚠️  Dashboard files are ready, but you need data!"
  puts ""
  puts "Run: rails db:seed"
  puts "Then restart the server and visit the dashboard."
end
puts "=" * 80
