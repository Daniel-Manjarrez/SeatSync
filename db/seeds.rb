# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Sample receipt data for testing
receipts = [
  {
    receipt_date: Date.parse('2025-01-15'),
    receipt_time: '08:00',
    order_items: ['Coffee', 'Croissant', 'Orange Juice']
  },
  {
    receipt_date: Date.parse('2025-01-15'),
    receipt_time: '12:30',
    order_items: ['Burger', 'Fries', 'Soda']
  },
  {
    receipt_date: Date.parse('2025-01-15'),
    receipt_time: '18:00',
    order_items: ['Salmon', 'Broccoli', 'Rice']
  },
  {
    receipt_date: Date.parse('2025-01-16'),
    receipt_time: '08:00',
    order_items: ['Pancakes', 'Eggs', 'Bacon']
  },
  {
    receipt_date: Date.parse('2025-01-16'),
    receipt_time: '12:00',
    order_items: ['Caesar Salad', 'Garlic Bread']
  }
]

receipts.each do |receipt|
  Receipt.create!(receipt)
end

puts "Created #{Receipt.count} sample receipts"
