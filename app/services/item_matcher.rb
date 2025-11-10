# app/services/item_matcher.rb
# Service to match OCR-extracted text to menu Item records using fuzzy matching

class ItemMatcher
  # Minimum similarity score to consider a match (0.0 to 1.0)
  SIMILARITY_THRESHOLD = 0.6
  
  def self.match(ocr_text, quantity: 1, line_price: nil)
    new.match(ocr_text, quantity: quantity, line_price: line_price)
  end
  
  def self.match_all(ocr_items, subtotal: nil)
    new.match_all(ocr_items, subtotal: subtotal)
  end
  
  def initialize
    @menu_items = Item.all.to_a
  end
  
  # Match a single OCR text string to a menu item
  # Returns: { item: Item, confidence: 0.85, quantity: 1 } or nil
  def match(ocr_text, quantity: 1, line_price: nil)
    return nil if ocr_text.blank?
    
    # Try different matching strategies
    result = try_exact_match(ocr_text) ||
             try_substring_match(ocr_text) ||
             try_fuzzy_match(ocr_text)
    
    if result
      # Store the OCR quantity (we'll validate against subtotal later)
      result.merge(quantity: quantity)
    else
      Rails.logger.info "❌ No match found for: #{ocr_text}"
      nil
    end
  end
  
  # Match multiple OCR items and validate quantities against subtotal
  # Input: [{ text: "Chicken Parm", ocr_quantity: 4, line_price: 18.00 }, ...]
  # Output: [{ item: Item, quantity: 1, confidence: 0.85, matched_text: "..." }, ...]
  def match_all(ocr_items, subtotal: nil)
    matched = []
    
    ocr_items.each do |ocr_item|
      text = ocr_item.is_a?(Hash) ? ocr_item[:text] : ocr_item
      qty = ocr_item.is_a?(Hash) ? (ocr_item[:ocr_quantity] || ocr_item[:quantity] || 1) : 1
      line_price = ocr_item.is_a?(Hash) ? ocr_item[:line_price] : nil
      
      result = match(text, quantity: qty, line_price: line_price)
      if result
        matched << result.merge(matched_text: text)
        Rails.logger.info "✅ Matched: '#{text}' → '#{result[:item].name}' (#{(result[:confidence] * 100).round}%, qty: #{result[:quantity]})"
      end
    end
    
    # Validate and correct quantities using subtotal if available
    if subtotal && subtotal > 0 && matched.any?
      matched = validate_quantities_with_subtotal(matched, subtotal)
    end
    
    matched
  end
  
  private
  
  # Strategy 1: Exact match (case-insensitive)
  def try_exact_match(ocr_text)
    item = @menu_items.find { |i| i.name.downcase == ocr_text.downcase }
    item ? { item: item, confidence: 1.0 } : nil
  end
  
  # Strategy 2: Substring match (menu item name contained in OCR text)
  def try_substring_match(ocr_text)
    ocr_lower = ocr_text.downcase
    
    matches = @menu_items.map do |item|
      item_lower = item.name.downcase
      
      # Check if item name is in OCR text or vice versa
      if ocr_lower.include?(item_lower)
        { item: item, confidence: 0.9 }
      elsif item_lower.include?(ocr_lower)
        { item: item, confidence: 0.85 }
      else
        nil
      end
    end.compact
    
    # Return best match
    matches.max_by { |m| m[:confidence] }
  end
  
  # Strategy 3: Fuzzy match using similarity score
  def try_fuzzy_match(ocr_text)
    matches = @menu_items.map do |item|
      similarity = calculate_similarity(ocr_text, item.name)
      
      if similarity >= SIMILARITY_THRESHOLD
        { item: item, confidence: similarity }
      else
        nil
      end
    end.compact
    
    # Return best match
    matches.max_by { |m| m[:confidence] }
  end
  
  # Calculate string similarity (0.0 to 1.0)
  def calculate_similarity(str1, str2)
    # Normalize strings
    s1 = str1.downcase.strip
    s2 = str2.downcase.strip
    
    # Calculate Levenshtein distance
    distance = levenshtein_distance(s1, s2)
    max_length = [s1.length, s2.length].max
    
    # Convert to similarity score (0.0 = no match, 1.0 = exact match)
    return 1.0 if max_length.zero?
    1.0 - (distance.to_f / max_length)
  end
  
  # Levenshtein distance (edit distance) algorithm
  # Measures minimum number of edits (insertions, deletions, substitutions) needed
  def levenshtein_distance(s1, s2)
    return s2.length if s1.empty?
    return s1.length if s2.empty?
    
    # Create matrix
    matrix = Array.new(s1.length + 1) { Array.new(s2.length + 1) }
    
    # Initialize first row and column
    (0..s1.length).each { |i| matrix[i][0] = i }
    (0..s2.length).each { |j| matrix[0][j] = j }
    
    # Fill matrix
    (1..s1.length).each do |i|
      (1..s2.length).each do |j|
        cost = s1[i - 1] == s2[j - 1] ? 0 : 1
        
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      # deletion
          matrix[i][j - 1] + 1,      # insertion
          matrix[i - 1][j - 1] + cost # substitution
        ].min
      end
    end
    
    matrix[s1.length][s2.length]
  end
  
  # Validate quantities against subtotal using constraint satisfaction
  # If sum(quantity × price) ≠ subtotal, try to find correct quantities
  def validate_quantities_with_subtotal(matched_items, actual_subtotal)
    return matched_items if matched_items.empty?
    
    # Calculate subtotal with OCR quantities
    ocr_subtotal = matched_items.sum { |m| m[:quantity] * m[:item].price }
    
    Rails.logger.info "💰 Subtotal validation: OCR=$#{ocr_subtotal.round(2)}, Actual=$#{actual_subtotal.round(2)}"
    
    # If subtotal matches (within $0.50), use OCR quantities
    if (ocr_subtotal - actual_subtotal).abs < 0.50
      Rails.logger.info "✓ Subtotal matches! Using OCR quantities."
      return matched_items
    end
    
    Rails.logger.warn "⚠️  Subtotal mismatch! Searching for correct quantities..."
    
    # Try to find correct quantities through search
    corrected = find_correct_quantities(matched_items, actual_subtotal)
    
    if corrected
      Rails.logger.info "✓ Found correct quantities! New subtotal: $#{corrected.sum { |m| m[:quantity] * m[:item].price }.round(2)}"
      return corrected
    else
      Rails.logger.warn "⚠️  Could not find matching quantities. Using OCR quantities as fallback."
      return matched_items
    end
  end
  
  # Search for quantities that match the subtotal
  # Uses constraint satisfaction to find valid combination
  def find_correct_quantities(matched_items, target_subtotal)
    return nil if matched_items.empty?
    
    # First, try direct calculation for single items
    if matched_items.length == 1
      item = matched_items.first
      correct_qty = (target_subtotal / item[:item].price).round
      if (correct_qty * item[:item].price - target_subtotal).abs < 0.50
        Rails.logger.warn "   Corrected #{item[:item].name}: #{item[:quantity]} → #{correct_qty}"
        return [item.merge(quantity: correct_qty)]
      end
    end
    
    # For multiple items, try all reasonable quantities (0-10 for each)
    # This handles OCR errors like reading 1 as 4, 7 as 1, etc.
    if matched_items.length <= 3
      # Generate all combinations of quantities (0..10 for each item)
      quantity_ranges = matched_items.map { (0..10).to_a }
      
      quantity_ranges[0].product(*quantity_ranges[1..-1]).each do |quantities|
        # Create test items with these quantities
        test_items = matched_items.map.with_index do |match, idx|
          match.merge(quantity: quantities[idx])
        end
        
        # Calculate subtotal
        test_subtotal = test_items.sum { |m| m[:quantity] * m[:item].price }
        
        # Check if it matches (within $0.50)
        if (test_subtotal - target_subtotal).abs < 0.50
          # Log the corrections
          matched_items.zip(test_items).each do |original, corrected|
            if original[:quantity] != corrected[:quantity]
              Rails.logger.warn "   Corrected #{original[:item].name}: #{original[:quantity]} → #{corrected[:quantity]}"
            end
          end
          return test_items
        end
      end
    else
      # For larger orders, use greedy approach: adjust one at a time
      current_items = matched_items.dup
      
      # Try adjusting each item
      matched_items.each_with_index do |match, idx|
        best_qty = match[:quantity]
        best_diff = (current_items.sum { |m| m[:quantity] * m[:item].price } - target_subtotal).abs
        
        # Try different quantities for this item
        (0..10).each do |test_qty|
          next if test_qty == match[:quantity]
          
          test_items = current_items.dup
          test_items[idx] = match.merge(quantity: test_qty)
          
          test_subtotal = test_items.sum { |m| m[:quantity] * m[:item].price }
          diff = (test_subtotal - target_subtotal).abs
          
          if diff < best_diff
            best_diff = diff
            best_qty = test_qty
          end
        end
        
        # Apply best quantity found
        if best_qty != match[:quantity]
          Rails.logger.warn "   Adjusted #{match[:item].name}: #{match[:quantity]} → #{best_qty}"
          current_items[idx] = match.merge(quantity: best_qty)
        end
        
        # Check if we've reached the target
        current_subtotal = current_items.sum { |m| m[:quantity] * m[:item].price }
        if (current_subtotal - target_subtotal).abs < 0.50
          return current_items
        end
      end
    end
    
    # No valid combination found
    nil
  end
end

