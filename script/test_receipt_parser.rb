# scripts/test_receipt_parser.rb
# Standalone tester for ReceiptParser

require_relative '../config/environment'

# Path to the sample image
file_path = Rails.root.join('spec', 'fixtures', 'files', 'SampleReceipt.jpg')

# Check file existence
unless File.exist?(file_path)
  puts "❌ File not found: #{file_path}"
  exit(1)
end

puts "📸 Reading and processing receipt: #{file_path}"

# Run OCR
begin
  ocr_text = RTesseract.new(file_path.to_s).to_s
  puts "\n===== OCR TEXT ====="
  puts ocr_text
rescue => e
  puts "❌ OCR failed: #{e.message}"
  exit(1)
end

# Parse using your existing service
begin
  parsed_data = ReceiptParser.parse_text(ocr_text)
  puts "\n===== PARSED DATA ====="
  puts "Merchant: #{parsed_data[:merchant_name]}" if parsed_data[:merchant_name]
  puts "Date: #{parsed_data[:purchase_date]}" if parsed_data[:purchase_date]
  puts "Time: #{parsed_data[:purchase_time]}" if parsed_data[:purchase_time]
  puts "Subtotal: #{parsed_data[:subtotal]}" if parsed_data[:subtotal]
  puts "Tax: #{parsed_data[:tax]}" if parsed_data[:tax]
  puts "Tip: #{parsed_data[:tip]}" if parsed_data[:tip]
  puts "Total: #{parsed_data[:total]}" if parsed_data[:total]

  puts "\nItems:"
  (parsed_data[:order_items] || []).each_with_index do |item, idx|
    puts "  #{idx + 1}. #{item[:name]} - $#{item[:price]}"
  end
rescue => e
  puts "❌ Parsing failed: #{e.message}"
end
