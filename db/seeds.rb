# Clear existing data
puts "Clearing existing data..."
ReceiptItem.destroy_all
Receipt.where.not(id: Receipt.joins(:receipt_items).select(:id)).destroy_all
Item.destroy_all
Ingredient.destroy_all

# ============================================
# 1. CREATE INGREDIENTS
# ============================================
puts "Creating ingredients..."

ingredients_data = [
  { name: 'Chicken', unit: 'lbs' },
  { name: 'Breadcrumbs', unit: 'lbs' },
  { name: 'Eggs', unit: 'lbs' },
  { name: 'Mozzarella', unit: 'lbs' },
  { name: 'Marinara sauce', unit: 'lbs' },
  { name: 'Eggplant', unit: 'lbs' },
  { name: 'Beef', unit: 'lbs' },
  { name: 'Pasta', unit: 'lbs' },
  { name: 'Tomatoes', unit: 'lbs' },
  { name: 'Cream', unit: 'lbs' },
  { name: 'Vodka', unit: 'lbs' },
  { name: 'Garlic', unit: 'lbs' },
  { name: 'Shrimp', unit: 'lbs' },
  { name: 'Ricotta', unit: 'lbs' },
  { name: 'Lettuce', unit: 'lbs' },
  { name: 'Dressing', unit: 'lbs' },
  { name: 'Parmesan', unit: 'lbs' },
  { name: 'Croutons', unit: 'lbs' },
  { name: 'Calamari', unit: 'lbs' },
  { name: 'Flour', unit: 'lbs' },
  { name: 'Oil', unit: 'lbs' },
  { name: 'Lemon', unit: 'lbs' },
  { name: 'Sugar', unit: 'lbs' },
  { name: 'Chocolate chips', unit: 'lbs' }
]

ingredients_data.each do |ingredient_attrs|
  Ingredient.create!(ingredient_attrs)
end

puts "Created #{Ingredient.count} ingredients"

# ============================================
# 2. CREATE MENU ITEMS WITH RECIPES
# ============================================
puts "Creating menu items with recipes..."

items_data = [
  {
    name: 'Chicken Parmesan',
    price: 20.00,
    category: 'Entrees',
    recipes: {
      'Chicken' => 0.5,
      'Breadcrumbs' => 0.05,
      'Eggs' => 0.05,
      'Mozzarella' => 0.15,
      'Marinara sauce' => 0.3
    }
  },
  {
    name: 'Eggplant Parmesan',
    price: 18.00,
    category: 'Entrees',
    recipes: {
      'Eggplant' => 0.4,
      'Breadcrumbs' => 0.05,
      'Eggs' => 0.05,
      'Mozzarella' => 0.15,
      'Marinara sauce' => 0.3
    }
  },
  {
    name: 'Meatball Parmesan',
    price: 19.00,
    category: 'Entrees',
    recipes: {
      'Beef' => 0.4,
      'Breadcrumbs' => 0.05,
      'Eggs' => 0.05,
      'Mozzarella' => 0.15,
      'Marinara sauce' => 0.3
    }
  },
  {
    name: 'Rigatoni with Vodka Sauce',
    price: 17.00,
    category: 'Entrees',
    recipes: {
      'Pasta' => 0.5,
      'Tomatoes' => 0.25,
      'Cream' => 0.1,
      'Vodka' => 0.03,
      'Garlic' => 0.01
    }
  },
  {
    name: 'Penne Scampi',
    price: 22.00,
    category: 'Entrees',
    recipes: {
      'Pasta' => 0.5,
      'Shrimp' => 0.3,
      'Garlic' => 0.02,
      'Cream' => 0.1
    }
  },
  {
    name: 'Spaghetti and Meatballs',
    price: 16.00,
    category: 'Entrees',
    recipes: {
      'Pasta' => 0.5,
      'Beef' => 0.35,
      'Breadcrumbs' => 0.05,
      'Eggs' => 0.05,
      'Marinara sauce' => 0.3
    }
  },
  {
    name: 'Baked Ziti',
    price: 16.00,
    category: 'Entrees',
    recipes: {
      'Pasta' => 0.5,
      'Ricotta' => 0.2,
      'Mozzarella' => 0.15,
      'Marinara sauce' => 0.3,
      'Eggs' => 0.05
    }
  },
  {
    name: 'Caesar Salad',
    price: 12.00,
    category: 'Appetizers',
    recipes: {
      'Lettuce' => 0.35,
      'Dressing' => 0.15,
      'Parmesan' => 0.05,
      'Croutons' => 0.05
    }
  },
  {
    name: 'Fried Calamari',
    price: 14.00,
    category: 'Appetizers',
    recipes: {
      'Calamari' => 0.4,
      'Flour' => 0.05,
      'Oil' => 0.03,
      'Lemon' => 0.1,
      'Marinara sauce' => 0.2
    }
  },
  {
    name: 'Cannoli',
    price: 8.00,
    category: 'Desserts',
    recipes: {
      'Flour' => 0.1,
      'Ricotta' => 0.2,
      'Sugar' => 0.05,
      'Eggs' => 0.05,
      'Chocolate chips' => 0.05
    }
  }
]

items_data.each do |item_attrs|
  Item.create!(item_attrs)
end

puts "Created #{Item.count} menu items"

# ============================================
# 3. CREATE SAMPLE RECEIPTS WITH ITEMS
# ============================================
puts "Creating sample receipts..."

# Receipt 1: Dinner for 2
receipt1 = Receipt.create!(
  receipt_date: Date.parse('2025-11-01'),
  receipt_time: '18:30',
  table_size: 2,
  total: 45.96
)
receipt1.receipt_items.create!([
  { item: Item.find_by(name: 'Chicken Parmesan'), quantity: 1 },
  { item: Item.find_by(name: 'Caesar Salad'), quantity: 1 },
  { item: Item.find_by(name: 'Penne Scampi'), quantity: 1 }
])

# Receipt 2: Family dinner
receipt2 = Receipt.create!(
  receipt_date: Date.parse('2025-11-02'),
  receipt_time: '19:00',
  table_size: 4,
  total: 67.93
)
receipt2.receipt_items.create!([
  { item: Item.find_by(name: 'Spaghetti and Meatballs'), quantity: 2 },
  { item: Item.find_by(name: 'Baked Ziti'), quantity: 1 },
  { item: Item.find_by(name: 'Caesar Salad'), quantity: 2 },
  { item: Item.find_by(name: 'Cannoli'), quantity: 2 }
])

# Receipt 3: Date night
receipt3 = Receipt.create!(
  receipt_date: Date.parse('2025-11-03'),
  receipt_time: '20:00',
  table_size: 2,
  total: 54.96
)
receipt3.receipt_items.create!([
  { item: Item.find_by(name: 'Eggplant Parmesan'), quantity: 1 },
  { item: Item.find_by(name: 'Rigatoni with Vodka Sauce'), quantity: 1 },
  { item: Item.find_by(name: 'Fried Calamari'), quantity: 1 },
  { item: Item.find_by(name: 'Cannoli'), quantity: 2 }
])

puts "Created #{Receipt.count} sample receipts"
puts "Created #{ReceiptItem.count} receipt items"

# ============================================
# SUMMARY
# ============================================
puts "\n" + "="*50
puts "SEEDING COMPLETE!"
puts "="*50
puts "Ingredients: #{Ingredient.count}"
puts "Menu Items: #{Item.count}"
puts "Receipts: #{Receipt.count}"
puts "Receipt Items: #{ReceiptItem.count}"
puts "\nYou can now test ingredient tracking!"
puts "="*50
