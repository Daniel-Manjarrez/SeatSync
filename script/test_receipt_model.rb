# script/test_receipt_model.rb
require_relative '../config/environment'

# Pick a sample receipt image
file_path = Rails.root.join('spec/fixtures/files/SampleReceipt.jpg')

unless File.exist?(file_path)
  puts "❌ Receipt image not found: #{file_path}"
  exit(1)
end

puts "📸 Reading and processing receipt: #{file_path}"

# Run OCR + parse
parsed_data = ReceiptParser.parse_text(RTesseract.new(file_path.to_s).to_s)

# Populate receipt attributes (model-like structure)
receipt_data = {
  date: parsed_data[:purchase_date],
  time: parsed_data[:purchase_time],
  items: parsed_data[:order_items].map { |i| i[:name] }, # only names
  subtotal: (parsed_data[:total] && parsed_data[:tax]) ? (parsed_data[:total] - parsed_data[:tax]) : nil,
  tax: parsed_data[:tax],
  total: parsed_data[:total]
}

# Print nicely
puts "===== RECEIPT DATA ====="
puts "Date: #{receipt_data[:date]}"
puts "Time: #{receipt_data[:time]}"
puts "Subtotal: #{receipt_data[:subtotal]}" if receipt_data[:subtotal]
puts "Tax: #{receipt_data[:tax]}" if receipt_data[:tax]
puts "Total: #{receipt_data[:total]}" if receipt_data[:total]
puts "\nItems:"
(receipt_data[:items] || []).each_with_index do |name, idx|
  puts "  #{idx + 1}. #{name}"
end




