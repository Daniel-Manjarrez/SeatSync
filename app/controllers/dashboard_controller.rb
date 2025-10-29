class DashboardController < ApplicationController
  layout 'dashboard'
  
  def index
    # === TOP METRICS (Overview) ===
    @total_orders = 50
    @occupancy_rate = 78.5
    @average_order_size = 3.2
    @average_spend = 24.50
    @quantity_per_customer = 188
    
    # === REVENUE TRENDS ===
    # Daily Revenue (Last 30 days)
    @daily_revenue = {
      'Oct 1' => 1200, 'Oct 2' => 1350, 'Oct 3' => 1180, 'Oct 4' => 1420,
      'Oct 5' => 1650, 'Oct 6' => 1890, 'Oct 7' => 1720, 'Oct 8' => 1340,
      'Oct 9' => 1280, 'Oct 10' => 1390, 'Oct 11' => 1450, 'Oct 12' => 1520,
      'Oct 13' => 1680, 'Oct 14' => 1920, 'Oct 15' => 1850, 'Oct 16' => 1430,
      'Oct 17' => 1380, 'Oct 18' => 1490, 'Oct 19' => 1560, 'Oct 20' => 1640,
      'Oct 21' => 1790, 'Oct 22' => 2010, 'Oct 23' => 1950, 'Oct 24' => 1520,
      'Oct 25' => 1480, 'Oct 26' => 1590, 'Oct 27' => 1670, 'Oct 28' => 1750
    }
    
    # Weekly Revenue (Last 8 weeks)
    @weekly_revenue = {
      'Week 1' => 8450, 'Week 2' => 9120, 'Week 3' => 8890,
      'Week 4' => 9450, 'Week 5' => 10200, 'Week 6' => 9850,
      'Week 7' => 10450, 'Week 8' => 10890
    }
    
    # Monthly Revenue (Last 12 months)
    @monthly_revenue = {
      'Nov 2023' => 32000, 'Dec 2023' => 38000, 'Jan 2024' => 30000,
      'Feb 2024' => 33000, 'Mar 2024' => 35000, 'Apr 2024' => 36500,
      'May 2024' => 38000, 'Jun 2024' => 40000, 'Jul 2024' => 42000,
      'Aug 2024' => 41000, 'Sep 2024' => 43500, 'Oct 2024' => 45000
    }
    
    # === REVENUE BY DAY OF WEEK ===
    @revenue_by_day = {
      'Monday' => 5200,
      'Tuesday' => 4800,
      'Wednesday' => 5400,
      'Thursday' => 6100,
      'Friday' => 8500,
      'Saturday' => 9200,
      'Sunday' => 6800
    }
    
    # === REVENUE BY MEAL PERIOD ===
    @revenue_by_meal_period = {
      'Breakfast (6-11 AM)' => 12500,
      'Lunch (11 AM-3 PM)' => 18900,
      'Dinner (3-9 PM)' => 28600,
      'Late Night (9 PM+)' => 5000
    }
    
    # === MOST & LEAST POPULAR ITEMS ===
    @most_popular_items = [
      { name: 'Burger', count: 245 },
      { name: 'Fries', count: 220 },
      { name: 'Pizza', count: 198 },
      { name: 'Caesar Salad', count: 175 },
      { name: 'Chicken Tenders', count: 165 },
      { name: 'Wings', count: 152 },
      { name: 'Pasta', count: 140 },
      { name: 'Tacos', count: 135 },
      { name: 'Sandwich', count: 128 },
      { name: 'Steak', count: 115 }
    ]
    
    @least_popular_items = [
      { name: 'Anchovies Pizza', count: 5 },
      { name: 'Liver & Onions', count: 8 },
      { name: 'Brussels Sprouts', count: 12 },
      { name: 'Sardine Salad', count: 15 },
      { name: 'Tofu Bowl', count: 18 },
      { name: 'Kale Smoothie', count: 22 },
      { name: 'Quinoa Salad', count: 25 },
      { name: 'Beet Salad', count: 28 },
      { name: 'Protein Bowl', count: 32 },
      { name: 'Green Juice', count: 35 }
    ]
    
    # === ITEM METRICS ===
    @average_items_per_order = 3.2
    
    # Item Attachment Rate (most common pairs)
    @item_attachments = [
      { item_a: 'Burger', item_b: 'Fries', rate: 85 },
      { item_a: 'Pizza', item_b: 'Soda', rate: 72 },
      { item_a: 'Wings', item_b: 'Ranch', rate: 68 },
      { item_a: 'Steak', item_b: 'Mashed Potatoes', rate: 65 },
      { item_a: 'Salad', item_b: 'Dressing', rate: 90 }
    ]
    
    # === PRICE POINT DISTRIBUTION ===
    @price_distribution = {
      '$0-10' => 12,
      '$10-20' => 28,
      '$20-30' => 35,
      '$30-40' => 18,
      '$40-50' => 15,
      '$50+' => 8
    }
    
    # === TIMING METRICS ===
    # Customer Timing by Hour
    @timing_data = {
      '11 AM' => 5, '12 PM' => 12, '1 PM' => 18, '2 PM' => 8,
      '3 PM' => 4, '4 PM' => 3, '5 PM' => 6, '6 PM' => 15,
      '7 PM' => 22, '8 PM' => 19, '9 PM' => 10, '10 PM' => 5
    }
    
    # Order Frequency by 15-minute intervals (during lunch rush)
    @fifteen_min_intervals = {
      '11:00' => 2, '11:15' => 4, '11:30' => 6, '11:45' => 8,
      '12:00' => 12, '12:15' => 18, '12:30' => 22, '12:45' => 16,
      '1:00' => 14, '1:15' => 10, '1:30' => 7, '1:45' => 5,
      '2:00' => 4, '2:15' => 3, '2:30' => 2, '2:45' => 1
    }
    
    @average_orders_per_hour = 6.2
    
    # Weekday vs Weekend
    @weekday_revenue = 26500
    @weekend_revenue = 19000
    @weekday_orders = 180
    @weekend_orders = 95
    
    @time_between_orders = 8.5  # minutes
    
    # === REVENUE BY CATEGORY ===
    @revenue_by_category = {
      'Appetizers' => 8500,
      'Entrees' => 28600,
      'Desserts' => 6200,
      'Beverages' => 7800,
      'Sides' => 4900
    }
    
    # Average Check Size by Time of Day
    @avg_check_by_time = {
      '11 AM' => 18.50, '12 PM' => 22.00, '1 PM' => 24.50,
      '2 PM' => 20.00, '3 PM' => 19.00, '4 PM' => 17.50,
      '5 PM' => 21.00, '6 PM' => 28.00, '7 PM' => 32.50,
      '8 PM' => 30.00, '9 PM' => 25.00, '10 PM' => 22.00
    }
    
    # === GROWTH METRICS ===
    @week_over_week_growth = 8.5  # percentage
    @month_over_month_growth = 12.3  # percentage
    
    # Product Performance for chart
    @product_data = [
      { name: 'Burger', amount: 28 }, { name: 'Chicken Tenders', amount: 26 },
      { name: 'Caesar Salad', amount: 24 }, { name: 'Pizza', amount: 23 },
      { name: 'Wings', amount: 22 }, { name: 'Pasta', amount: 21 },
      { name: 'Tacos', amount: 20 }, { name: 'Sandwich', amount: 19 },
      { name: 'Steak', amount: 18 }, { name: 'Salmon', amount: 17 }
    ]
  end
end
