# Step: Mock the receipt parser to return test data
Given('the receipt parser will return test data') do
  # Create test items that will be matched
  Item.find_or_create_by!(name: 'Burger') do |item|
    item.price = 14.99
    item.category = 'Entrees'
  end
  Item.find_or_create_by!(name: 'Fries') do |item|
    item.price = 3.99
    item.category = 'Sides'
  end
  Item.find_or_create_by!(name: 'Soda') do |item|
    item.price = 2.99
    item.category = 'Beverages'
  end

  # Mock the ReceiptParser to return expected data
  parsed_data = {
    date: Date.parse('2025-01-15'),
    time: '14:30',
    items: [
      { text: 'Burger', quantity: 1 },
      { text: 'Fries', quantity: 1 },
      { text: 'Soda', quantity: 1 }
    ],
    subtotal: 21.97,
    total: 23.97,
    tip: 2.00
  }

  allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(parsed_data)
end

# Step: Attach a receipt image
When('I attach a receipt image') do
  attach_file('receipt_image', Rails.root.join('spec/fixtures/files/sample_receipt.jpg'))
end

# Step: Create a receipt in the database
Given('a receipt exists with date {string} and time {string}') do |date, time|
  # Create test items if they don't exist
  item1 = Item.find_or_create_by!(name: 'Test Item 1') do |item|
    item.price = 10.99
    item.category = 'Entrees'
  end
  item2 = Item.find_or_create_by!(name: 'Test Item 2') do |item|
    item.price = 8.99
    item.category = 'Appetizers'
  end

  receipt = Receipt.create!(
    receipt_date: Date.parse(date),
    receipt_time: time,
    order_items: ['Test Item 1', 'Test Item 2']
  )

  # Create receipt_items
  receipt.receipt_items.create!(item: item1, quantity: 1)
  receipt.receipt_items.create!(item: item2, quantity: 1)
end
