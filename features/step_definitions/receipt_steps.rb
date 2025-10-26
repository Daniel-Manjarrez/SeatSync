# Step: Attach a receipt image
When('I attach a receipt image') do
  attach_file('receipt_image', Rails.root.join('spec/fixtures/files/sample_receipt.jpg'))
end

# Step: Create a receipt in the database
Given('a receipt exists with date {string} and time {string}') do |date, time|
  Receipt.create!(
    receipt_date: Date.parse(date),
    receipt_time: time,
    order_items: ['Test Item 1', 'Test Item 2']
  )
end
