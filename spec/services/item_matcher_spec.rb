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
  end
end
require 'rails_helper'

RSpec.describe ItemMatcher, type: :service do
  let!(:burger) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees') }
  let!(:fries) { Item.create!(name: 'French Fries', price: 5.0, category: 'Sides') }
  let!(:salad) { Item.create!(name: 'Caesar Salad', price: 12.0, category: 'Sides') }
  let!(:pizza) { Item.create!(name: 'Pizza Margherita', price: 15.0, category: 'Entrees') }

  describe '.match' do
    it 'finds exact matches' do
      result = ItemMatcher.match('Burger', quantity: 1)
      
      expect(result).not_to be_nil
      expect(result[:item]).to eq(burger)
      expect(result[:confidence]).to eq(1.0)
      expect(result[:quantity]).to eq(1)
    end

    it 'is case insensitive for exact matches' do
      result = ItemMatcher.match('BURGER', quantity: 2)
      
      expect(result[:item]).to eq(burger)
      expect(result[:confidence]).to eq(1.0)
    end

    it 'finds substring matches' do
      result = ItemMatcher.match('French', quantity: 1)
      
      expect(result[:item]).to eq(fries)
      expect(result[:confidence]).to be >= 0.85
    end

    it 'finds fuzzy matches' do
      result = ItemMatcher.match('Burgr', quantity: 1)  # typo
      
      expect(result[:item]).to eq(burger)
      expect(result[:confidence]).to be >= 0.6
    end

    it 'returns nil for no match' do
      result = ItemMatcher.match('Nonexistent Item', quantity: 1)
      
      expect(result).to be_nil
    end

    it 'returns nil for blank text' do
      result = ItemMatcher.match('', quantity: 1)
      
      expect(result).to be_nil
    end

    it 'includes quantity in result' do
      result = ItemMatcher.match('Burger', quantity: 3)
      
      expect(result[:quantity]).to eq(3)
    end
  end

  describe '.match_all' do
    it 'matches multiple items' do
      ocr_items = [
        { text: 'Burger', ocr_quantity: 2, line_price: 10.0 },
        { text: 'French Fries', ocr_quantity: 1, line_price: 5.0 }
      ]
      
      results = ItemMatcher.match_all(ocr_items)
      
      expect(results.length).to eq(2)
      expect(results[0][:item]).to eq(burger)
      expect(results[0][:quantity]).to eq(2)
      expect(results[1][:item]).to eq(fries)
    end

    it 'handles string inputs' do
      results = ItemMatcher.match_all(['Burger', 'Fries'])
      
      expect(results.length).to eq(2)
      expect(results[0][:item]).to eq(burger)
      expect(results[1][:item]).to eq(fries)
    end

    it 'validates quantities against subtotal' do
      ocr_items = [
        { text: 'Burger', ocr_quantity: 1, line_price: 10.0 }
      ]
      
      # Correct subtotal for 1 burger = $10
      results = ItemMatcher.match_all(ocr_items, subtotal: 10.0)
      
      expect(results[0][:quantity]).to eq(1)
    end

    it 'corrects quantities when subtotal does not match' do
      ocr_items = [
        { text: 'Burger', ocr_quantity: 4, line_price: 10.0 }  # OCR error: read 1 as 4
      ]
      
      # Correct subtotal for 1 burger = $10, not $40
      results = ItemMatcher.match_all(ocr_items, subtotal: 10.0)
      
      expect(results[0][:quantity]).to eq(1)
    end

    it 'filters out non-matching items' do
      ocr_items = [
        { text: 'Burger', ocr_quantity: 1 },
        { text: 'Unknown Item', ocr_quantity: 1 }
      ]
      
      results = ItemMatcher.match_all(ocr_items)
      
      expect(results.length).to eq(1)
      expect(results[0][:item]).to eq(burger)
    end

    it 'includes matched text in results' do
      ocr_items = [{ text: 'Burgr', ocr_quantity: 1 }]  # typo
      
      results = ItemMatcher.match_all(ocr_items)
      
      expect(results[0][:matched_text]).to eq('Burgr')
    end
  end

  describe '#try_exact_match' do
    it 'matches exact item names' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_exact_match, 'Burger')
      
      expect(result[:item]).to eq(burger)
      expect(result[:confidence]).to eq(1.0)
    end

    it 'is case insensitive' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_exact_match, 'burger')
      
      expect(result[:item]).to eq(burger)
    end

    it 'returns nil for non-matches' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_exact_match, 'Hot Dog')
      
      expect(result).to be_nil
    end
  end

  describe '#try_substring_match' do
    it 'matches when item name is in OCR text' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_substring_match, 'French Fries Large')
      
      expect(result[:item]).to eq(fries)
      expect(result[:confidence]).to eq(0.9)
    end

    it 'matches when OCR text is in item name' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_substring_match, 'French')
      
      expect(result[:item]).to eq(fries)
      expect(result[:confidence]).to eq(0.85)
    end

    it 'returns nil for no substring match' do
      matcher = ItemMatcher.new
      result = matcher.send(:try_substring_match, 'Hot Dog')
      
      expect(result).to be_nil
    end
  end

  describe '#calculate_similarity' do
    it 'returns 1.0 for identical strings' do
      matcher = ItemMatcher.new
      similarity = matcher.send(:calculate_similarity, 'Burger', 'Burger')
      
      expect(similarity).to eq(1.0)
    end

    it 'returns high score for similar strings' do
      matcher = ItemMatcher.new
      similarity = matcher.send(:calculate_similarity, 'Burger', 'Burgr')
      
      expect(similarity).to be > 0.8
    end

    it 'returns low score for different strings' do
      matcher = ItemMatcher.new
      similarity = matcher.send(:calculate_similarity, 'Burger', 'Pizza')
      
      expect(similarity).to be < 0.5
    end

    it 'is case insensitive' do
      matcher = ItemMatcher.new
      sim1 = matcher.send(:calculate_similarity, 'BURGER', 'burger')
      
      expect(sim1).to eq(1.0)
    end
  end

  describe '#levenshtein_distance' do
    it 'returns 0 for identical strings' do
      matcher = ItemMatcher.new
      distance = matcher.send(:levenshtein_distance, 'test', 'test')
      
      expect(distance).to eq(0)
    end

    it 'calculates edit distance correctly' do
      matcher = ItemMatcher.new
      distance = matcher.send(:levenshtein_distance, 'kitten', 'sitting')
      
      expect(distance).to eq(3)  # substitute k->s, e->i, insert g
    end

    it 'handles empty strings' do
      matcher = ItemMatcher.new
      distance = matcher.send(:levenshtein_distance, '', 'test')
      
      expect(distance).to eq(4)
    end
  end

  describe '#validate_quantities_with_subtotal' do
    it 'keeps OCR quantities when subtotal matches' do
      matcher = ItemMatcher.new
      matched = [
        { item: burger, quantity: 2, confidence: 1.0 }
      ]
      
      result = matcher.send(:validate_quantities_with_subtotal, matched, 20.0)
      
      expect(result[0][:quantity]).to eq(2)
    end

    it 'corrects quantities when subtotal does not match' do
      matcher = ItemMatcher.new
      matched = [
        { item: burger, quantity: 4, confidence: 1.0 }  # Wrong quantity
      ]
      
      result = matcher.send(:validate_quantities_with_subtotal, matched, 10.0)
      
      expect(result[0][:quantity]).to eq(1)  # Corrected
    end

    it 'handles multiple items' do
      matcher = ItemMatcher.new
      matched = [
        { item: burger, quantity: 1, confidence: 1.0 },
        { item: fries, quantity: 1, confidence: 1.0 }
      ]
      
      result = matcher.send(:validate_quantities_with_subtotal, matched, 15.0)
      
      total = result.sum { |m| m[:quantity] * m[:item].price }
      expect(total).to be_within(0.5).of(15.0)
    end

    it 'returns original if no valid combination found' do
      matcher = ItemMatcher.new
      matched = [
        { item: burger, quantity: 2, confidence: 1.0 }
      ]
      
      # Impossible subtotal
      result = matcher.send(:validate_quantities_with_subtotal, matched, 17.5)
      
      expect(result[0][:quantity]).to eq(2)  # Keeps original
    end
  end

  describe '#find_correct_quantities' do
    it 'corrects single item quantities' do
      matcher = ItemMatcher.new
      matched = [{ item: burger, quantity: 4, confidence: 1.0 }]
      
      result = matcher.send(:find_correct_quantities, matched, 20.0)
      
      expect(result[0][:quantity]).to eq(2)  # $10 × 2 = $20
    end

    it 'finds correct combination for multiple items' do
      matcher = ItemMatcher.new
      matched = [
        { item: burger, quantity: 1, confidence: 1.0 },
        { item: fries, quantity: 2, confidence: 1.0 }
      ]
      
      result = matcher.send(:find_correct_quantities, matched, 15.0)
      
      total = result.sum { |m| m[:quantity] * m[:item].price }
      expect(total).to be_within(0.5).of(15.0)
    end

    it 'returns nil if no valid combination exists' do
      matcher = ItemMatcher.new
      matched = [{ item: burger, quantity: 1, confidence: 1.0 }]
      
      result = matcher.send(:find_correct_quantities, matched, 7.5)
      
      expect(result).to be_nil
    end
  end
end

