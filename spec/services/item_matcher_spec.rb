require 'rails_helper'

RSpec.describe ItemMatcher do
  describe '#match' do
    before do
      Item.create!(name: 'Burger', price: 10.0, category: 'Entrees')
      Item.create!(name: 'Cheese Burger', price: 12.0, category: 'Entrees')
      Item.create!(name: 'Chocolate Cake', price: 6.0, category: 'Desserts')
    end

    it 'finds exact matches (case-insensitive) with confidence 1.0' do
      result = ItemMatcher.match('burger')
      expect(result).not_to be_nil
      expect(result[:item].name).to eq('Burger')
      expect(result[:confidence]).to eq(1.0)
      expect(result[:quantity]).to eq(1)
    end

    it 'finds substring matches and returns a high confidence' do
      result = ItemMatcher.match('Cheese Burger Deluxe')
      expect(result).not_to be_nil
      # Depending on menu ordering, the match may return either the
      # exact 'Cheese Burger' or the simpler 'Burger' item; ensure
      # confidence is high and matched item relates to burger text.
      expect(result[:confidence]).to be >= 0.85
      expect(result[:item].name.downcase).to include('burger')
    end

    it 'finds fuzzy matches for slightly misspelled names' do
      result = ItemMatcher.match('Choclate Cak')
      expect(result).not_to be_nil
      expect(result[:item].name).to eq('Chocolate Cake')
      expect(result[:confidence]).to be >= ItemMatcher::SIMILARITY_THRESHOLD
    end
  end

  describe '#match_all with subtotal correction' do
    it 'corrects quantities for a single item when subtotal differs' do
      item = Item.create!(name: 'Slice', price: 5.0, category: 'Desserts')

      ocr_items = [ { text: 'Slice', ocr_quantity: 4, line_price: nil } ]

      matched = ItemMatcher.match_all(ocr_items, subtotal: 10.0)
      expect(matched.length).to eq(1)
      expect(matched.first[:item]).to eq(item)
      # OCR quantity 4 -> corrected to 2 (2 * 5.0 = 10.0)
      expect(matched.first[:quantity]).to eq(2)
    end

    it 'uses greedy approach for orders with more than 3 items' do
      item1 = Item.create!(name: 'Pizza', price: 12.0, category: 'Entrees')
      item2 = Item.create!(name: 'Salad', price: 8.0, category: 'Sides')
      item3 = Item.create!(name: 'Soda', price: 2.0, category: 'Beverages')
      item4 = Item.create!(name: 'Dessert', price: 5.0, category: 'Desserts')

      ocr_items = [
        { text: 'Pizza', ocr_quantity: 1, line_price: 12.0 },
        { text: 'Salad', ocr_quantity: 1, line_price: 8.0 },
        { text: 'Soda', ocr_quantity: 2, line_price: 2.0 },
        { text: 'Dessert', ocr_quantity: 1, line_price: 5.0 }
      ]

      # Correct subtotal: 12 + 8 + (2*2) + 5 = 29
      matched = ItemMatcher.match_all(ocr_items, subtotal: 29.0)

      expect(matched.length).to eq(4)
      expect(matched.sum { |m| m[:quantity] * m[:item].price }).to be_within(0.50).of(29.0)
    end

    it 'returns original quantities when greedy search fails' do
      item1 = Item.create!(name: 'Item1', price: 7.0, category: 'Entrees')
      item2 = Item.create!(name: 'Item2', price: 11.0, category: 'Sides')
      item3 = Item.create!(name: 'Item3', price: 13.0, category: 'Beverages')
      item4 = Item.create!(name: 'Item4', price: 17.0, category: 'Desserts')

      ocr_items = [
        { text: 'Item1', ocr_quantity: 1, line_price: 7.0 },
        { text: 'Item2', ocr_quantity: 1, line_price: 11.0 },
        { text: 'Item3', ocr_quantity: 1, line_price: 13.0 },
        { text: 'Item4', ocr_quantity: 1, line_price: 17.0 }
      ]

      # Impossible subtotal
      matched = ItemMatcher.match_all(ocr_items, subtotal: 999.0)

      expect(matched.length).to eq(4)
      # Should return original OCR quantities since no valid combination found
      expect(matched.all? { |m| m[:quantity] == 1 }).to be true
    end
  end

  describe '#match returns nil for blank text' do
    it 'returns nil when OCR text is empty string' do
      result = ItemMatcher.match('')
      expect(result).to be_nil
    end

    it 'returns nil when OCR text is nil' do
      result = ItemMatcher.match(nil)
      expect(result).to be_nil
    end

    it 'returns nil when OCR text is only whitespace' do
      result = ItemMatcher.match('   ')
      expect(result).to be_nil
    end
  end

  describe 'Levenshtein distance calculation' do
    it 'calculates similarity for similar strings' do
      Item.create!(name: 'Espresso', price: 3.0, category: 'Beverages')
      result = ItemMatcher.match('Esspresso')

      expect(result).not_to be_nil
      expect(result[:item].name).to eq('Espresso')
    end

    it 'handles empty strings in similarity calculation' do
      matcher = ItemMatcher.new
      similarity = matcher.send(:calculate_similarity, '', 'test')
      expect(similarity).to be >= 0
      expect(similarity).to be <= 1.0
    end

    it 'returns 1.0 for identical strings' do
      matcher = ItemMatcher.new
      similarity = matcher.send(:calculate_similarity, 'burger', 'burger')
      expect(similarity).to eq(1.0)
    end
  end

  describe '#match_all without subtotal' do
    it 'uses OCR quantities when no subtotal provided' do
      item = Item.create!(name: 'Coffee', price: 3.0, category: 'Beverages')

      ocr_items = [ { text: 'Coffee', ocr_quantity: 5, line_price: 3.0 } ]

      matched = ItemMatcher.match_all(ocr_items, subtotal: nil)

      expect(matched.length).to eq(1)
      expect(matched.first[:quantity]).to eq(5)
    end

    it 'uses OCR quantities when subtotal is zero' do
      item = Item.create!(name: 'Tea', price: 2.0, category: 'Beverages')

      ocr_items = [ { text: 'Tea', ocr_quantity: 3, line_price: 2.0 } ]

      matched = ItemMatcher.match_all(ocr_items, subtotal: 0)

      expect(matched.length).to eq(1)
      expect(matched.first[:quantity]).to eq(3)
    end
  end

  describe '#match_all with empty items array' do
    it 'returns empty array for no items' do
      matched = ItemMatcher.match_all([], subtotal: 10.0)
      expect(matched).to eq([])
    end
  end

  describe '#match with quantity parameter' do
    it 'includes quantity in result' do
      Item.create!(name: 'Pasta', price: 14.0, category: 'Entrees')
      result = ItemMatcher.match('Pasta', quantity: 3)

      expect(result[:quantity]).to eq(3)
    end
  end

  describe 'no match found logging' do
    it 'logs when no match is found and returns nil' do
      Item.create!(name: 'Burger', price: 10.0, category: 'Entrees')

      # Mock the logger to verify it's called
      allow(Rails.logger).to receive(:info)

      result = ItemMatcher.match('Completely Unknown Item That Does Not Exist')

      expect(result).to be_nil
      expect(Rails.logger).to have_received(:info).with(/No match found/)
    end
  end

  describe 'substring match edge cases' do
    it 'matches when menu item contains OCR text (reverse substring)' do
      Item.create!(name: 'Cheeseburger Deluxe', price: 15.0, category: 'Entrees')

      # OCR text "Cheese" is contained in "Cheeseburger Deluxe"
      result = ItemMatcher.match('Cheese')

      expect(result).not_to be_nil
      expect(result[:item].name).to eq('Cheeseburger Deluxe')
      expect(result[:confidence]).to eq(0.85)
    end

    it 'returns nil when neither substring condition is met' do
      Item.create!(name: 'Pizza Margherita', price: 15.0, category: 'Entrees')

      # This OCR text has no substring match with "Pizza Margherita"
      result = ItemMatcher.match('Totally Different Food')

      expect(result).to be_nil
    end
  end

  describe 'greedy algorithm return path' do
    it 'returns current_items when subtotal matches within tolerance' do
      item1 = Item.create!(name: 'Item1', price: 10.0, category: 'Entrees')
      item2 = Item.create!(name: 'Item2', price: 8.0, category: 'Sides')
      item3 = Item.create!(name: 'Item3', price: 5.0, category: 'Beverages')
      item4 = Item.create!(name: 'Item4', price: 3.0, category: 'Desserts')

      ocr_items = [
        { text: 'Item1', ocr_quantity: 1, line_price: 10.0 },
        { text: 'Item2', ocr_quantity: 1, line_price: 8.0 },
        { text: 'Item3', ocr_quantity: 1, line_price: 5.0 },
        { text: 'Item4', ocr_quantity: 1, line_price: 3.0 }
      ]

      # Perfect match: 10 + 8 + 5 + 3 = 26
      matched = ItemMatcher.match_all(ocr_items, subtotal: 26.0)

      expect(matched.length).to eq(4)
      total = matched.sum { |m| m[:quantity] * m[:item].price }
      expect(total).to eq(26.0)
    end
  end
end
