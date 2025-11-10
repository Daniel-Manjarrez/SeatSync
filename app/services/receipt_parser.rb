require 'rtesseract'

class ReceiptParser
  def initialize(image)
    @image = image
  end

  def parse
    # Download the attached file to a temp path
    tempfile = Tempfile.new(['receipt', '.jpg'])
    tempfile.binmode
    tempfile.write(@image.download)
    tempfile.rewind

    # Run OCR
    ocr = RTesseract.new(tempfile.path)
    text = ocr.to_s.strip

    # Extract values using regexes or heuristics
    subtotal = extract_subtotal(text)
    total = extract_total(text)
    tip = extract_tip(text)
    tax = extract_tax(text)
    
    # Smart fallback: If total seems wrong, calculate it
    # (handles OCR errors like reading "39" as "33")
    if subtotal && tax && (!total || (subtotal + tax - total).abs > 1.0)
      calculated_total = subtotal + tax
      Rails.logger.info "OCR total (#{total}) seems wrong. Calculated: #{calculated_total} (subtotal #{subtotal} + tax #{tax})"
      total = calculated_total
    end
    
    {
      date: extract_date(text),
      time: extract_time(text),
      items: extract_items_with_quantities(text),
      subtotal: subtotal,
      total: total,
      tip: tip,
      success: true
    }
  rescue => e
    # If parsing fails, return defaults
    Rails.logger.error "Receipt parsing failed: #{e.message}"
    {
      date: Date.today,
      time: Time.now.strftime('%H:%M'),
      items: [],
      subtotal: nil,
      total: nil,
      tip: nil,
      success: false
    }
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  private

  def extract_date(text)
    # Common receipt date patterns
    date_pattern = /\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})\b/
    match = text.match(date_pattern)
    if match
      # Assume format is MM/DD/YYYY on receipt
      month, day, year = match[1].split(/[\/\-\.]/).map(&:to_i)
      Date.new(year, month, day)
    else
      Date.today
    end
  end  

  def extract_time(text)
    # Match HH:MM or HH:MM AM/PM
    time_pattern = /\b(\d{1,2}:\d{2}(?:\s?[AP]M)?)\b/i
    match = text.match(time_pattern)
    match ? match[1].strip : Time.now.strftime('%H:%M')
  end

  def extract_items(text)
    # Basic heuristic: look for lines that include prices or food-like items
    lines = text.split("\n").map(&:strip)
    lines.select { |l| l.match?(/[A-Za-z]+\s+\d+(\.\d{2})?/) }.map do |line|
      line.split(/\s+\d/).first.strip
    end.uniq
  end
  
  def extract_items_with_quantities(text)
    # Extract items with quantity from lines like "2 Chicken Parmesan 18.00" or "1 Pizza 12"
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    items = []
    
    lines.each do |line|
      # Match pattern: [quantity] [item name...] [price]
      # Example: "4 Chicken Parm 18.00" or "1 Pizza 12"
      if line.match?(/^(\d+)\s+([A-Za-z])/i)
        # Capture quantity, item name, and price
        match = line.match(/^(\d+)\s+([A-Za-z][A-Za-z\s]+?)(?:\s+)?(\d+\.?\d{0,2})?\s*$/i)
        next unless match
        
        ocr_quantity = match[1].to_i
        item_name = match[2].strip
        line_price = match[3]&.to_f  # The price shown on this line (may be nil)
        
        # Filter out non-food lines
        next if item_name.match?(/^(subtotal|tax|total|cash|change|visa|card|check|order|phone|us-|ng\s)/i)
        next if item_name.length < 3
        
        items << { 
          text: item_name, 
          ocr_quantity: ocr_quantity,
          line_price: line_price  # Store for validation
        }
      end
    end
    
    items
  end
  
  def extract_subtotal(text)
    # Match "subtotal", "sub total", or OCR errors like "suptotal"
    match = text.match(/(?:sub|sup)\s?total[:\s]+(\d+\.?\d{0,2})/i)
    match ? match[1].to_f : nil
  end
  
  def extract_total(text)
    # Match "Total" but NOT "subtotal", "suptotal", "sub total"
    # Look for "Total" at word boundary or start of line
    lines = text.split("\n")
    
    # Find line with just "Total" (not subtotal/suptotal)
    total_line = lines.find do |line|
      line.match?(/^(?!.*(?:sub|sup)).*\btotal\b/i)
    end
    
    if total_line
      # Extract the number from that line
      match = total_line.match(/(\d+\.?\d{0,2})/)
      match ? match[1].to_f : nil
    else
      nil
    end
  end
  
  def extract_tip(text)
    # Match "tip 5.00" or "Tip: 5.00"
    match = text.match(/\btip[:\s]+(\d+\.?\d{0,2})/i)
    match ? match[1].to_f : nil
  end
  
  def extract_tax(text)
    # Match "tax 3.60", "Tax: 3.60", or OCR errors like "Tex"
    match = text.match(/\bt[ae]x[:\s]+(\d+\.?\d{0,2})/i)
    match ? match[1].to_f : nil
  end
end
