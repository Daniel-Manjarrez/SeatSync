Given('the OCR text is:') do |text|
  @ocr_text = text
end

Given('a fake receipt image is available') do
  @fake_receipt_image = instance_double('ActiveStorage::Blob', download: 'fake-image-bytes')
end

Given('the OCR engine will return that text') do
  raise 'OCR text not defined' unless @ocr_text

  @fake_ocr_client = instance_double('LlmOcrClient')
  allow(@fake_ocr_client).to receive(:extract_text).and_return(@ocr_text)
end

Given('the OCR engine will raise {string}') do |message|
  @fake_ocr_client = instance_double('LlmOcrClient')
  allow(@fake_ocr_client).to receive(:extract_text).and_raise(StandardError.new(message))
end

When('I parse the receipt image') do
  raise 'Fake receipt image not configured' unless @fake_receipt_image

  parser = ReceiptParser.new(@fake_receipt_image, ocr_client: @fake_ocr_client)
  @parsed_receipt = parser.parse
end

Then('the parsed date should be {string}') do |expected_date|
  expect(@parsed_receipt[:date]).to eq(Date.parse(expected_date))
end

Then('the parsed time should be {string}') do |expected_time|
  expect(@parsed_receipt[:time]).to eq(expected_time)
end

Then('the parsed subtotal should be {float}') do |expected_subtotal|
  expect(@parsed_receipt[:subtotal]).to be_within(0.01).of(expected_subtotal)
end

Then('the parsed total should equal the subtotal plus tax') do
  expect(@parsed_receipt[:subtotal]).not_to be_nil
  expect(@parsed_receipt[:total]).not_to be_nil

  tax_match = @ocr_text&.match(/\bt[ae]x[:\s]+(\d+\.?\d{0,2})/i)
  expected_tax = tax_match ? tax_match[1].to_f : 0.0
  expected_total = @parsed_receipt[:subtotal] + expected_tax

  expect(@parsed_receipt[:total]).to be_within(0.01).of(expected_total)
end

Then('the parsed tip should be {float}') do |expected_tip|
  expect(@parsed_receipt[:tip]).to be_within(0.01).of(expected_tip)
end

Then('the parsed items should include:') do |table|
  expected_rows = table.hashes
  actual = @parsed_receipt[:items]

  expected_rows.each do |row|
    matching = actual.find { |item| item[:text] == row['text'] }
    expect(matching).not_to be_nil, "Expected to find item #{row['text']}"
    expect(matching[:ocr_quantity]).to eq(row['quantity'].to_i)
    if row['line_price']
      expect(matching[:line_price]).to be_within(0.01).of(row['line_price'].to_f)
    end
  end
end

Then('parsing should succeed') do
  expect(@parsed_receipt[:success]).to be true
end

Then('parsing should fail with defaults') do
  expect(@parsed_receipt[:success]).to be false
  expect(@parsed_receipt[:items]).to eq([])
  expect(@parsed_receipt[:subtotal]).to be_nil
  expect(@parsed_receipt[:date]).to be_a(Date)
  expect(@parsed_receipt[:time]).to be_a(String)
end

