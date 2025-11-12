Given('the menu database is cleared') do
  ReceiptItem.delete_all
  Receipt.delete_all
  Item.delete_all
  Ingredient.delete_all
end

Given('the following menu items exist:') do |table|
  table.hashes.each do |row|
    Item.create!(
      name: row['name'],
      price: row['price'].to_f,
      category: row['category'] || 'Entrees'
    )
  end
end

When('I match OCR items with subtotal {float}:') do |subtotal, table|
  ocr_items = table.hashes.map do |row|
    quantity = row['quantity'] ? row['quantity'].to_i : 1
    item_hash = { text: row['text'], ocr_quantity: quantity, quantity: quantity }
    item_hash[:line_price] = row['line_price'].to_f if row['line_price']
    item_hash
  end

  matcher = ItemMatcher.new
  @match_results = matcher.match_all(ocr_items, subtotal: subtotal)
end

Then('the matched results should be:') do |table|
  expected = table.hashes
  expect(@match_results.length).to eq(expected.length)

  expected.each_with_index do |row, index|
    result = @match_results[index]
    expect(result[:matched_text]).to eq(row['text'])
    expect(result[:item].name).to eq(row['item'])
    expect(result[:quantity]).to eq(row['quantity'].to_i)

    if row['confidence']
      expect(result[:confidence]).to be_within(0.01).of(row['confidence'].to_f)
    end
  end
end

When('I match the OCR text {string}') do |text|
  matcher = ItemMatcher.new
  @single_match_result = matcher.match(text)
end

Then('the single match should be {string} with confidence {float}') do |item_name, expected_confidence|
  expect(@single_match_result).not_to be_nil
  expect(@single_match_result[:item].name).to eq(item_name)
  expect(@single_match_result[:confidence]).to be_within(0.01).of(expected_confidence)
end

Then('the single match should be {string} with confidence above {float}') do |item_name, threshold|
  expect(@single_match_result).not_to be_nil
  expect(@single_match_result[:item].name).to eq(item_name)
  expect(@single_match_result[:confidence]).to be > threshold
end

Then('there should be no match') do
  expect(@single_match_result).to be_nil
end

