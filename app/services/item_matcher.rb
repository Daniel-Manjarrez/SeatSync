# app/services/item_matcher.rb
# Service to match OCR-extracted text to menu Item records using fuzzy matching

class ItemMatcher
  # Minimum similarity score to consider a match (0.0 to 1.0)
  SIMILARITY_THRESHOLD = 0.6
  
  def self.match(ocr_text, quantity: 1)
    new.match(ocr_text, quantity: quantity)
  end
  
  def self.match_all(ocr_items)
    new.match_all(ocr_items)
  end
  
  def initialize
    @menu_items = Item.all.to_a
  end
  
  # Match a single OCR text string to a menu item
  # Returns: { item: Item, confidence: 0.85, quantity: 1 } or nil
  def match(ocr_text, quantity: 1)
    return nil if ocr_text.blank?
    
    # Try different matching strategies
    result = try_exact_match(ocr_text) ||
             try_substring_match(ocr_text) ||
             try_fuzzy_match(ocr_text)
    
    if result
      result.merge(quantity: quantity)
    else
      Rails.logger.info "❌ No match found for: #{ocr_text}"
      nil
    end
  end
  
  # Match multiple OCR items
  # Input: [{ text: "Chicken Parm", quantity: 2 }, ...]
  # Output: [{ item: Item, quantity: 2, confidence: 0.85, matched_text: "..." }, ...]
  def match_all(ocr_items)
    matched = []
    
    ocr_items.each do |ocr_item|
      text = ocr_item.is_a?(Hash) ? ocr_item[:text] : ocr_item
      qty = ocr_item.is_a?(Hash) ? ocr_item[:quantity] : 1
      
      result = match(text, quantity: qty)
      if result
        matched << result.merge(matched_text: text)
        Rails.logger.info "✅ Matched: '#{text}' → '#{result[:item].name}' (#{(result[:confidence] * 100).round}%)"
      end
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
end

