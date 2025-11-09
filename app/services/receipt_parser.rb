require 'rtesseract'

class ReceiptParser
  def initialize(image)
    @image = image
  end

  # Option to parse plain text without image
  def self.parse_text(text)
    parser = new(nil)
    {
      merchant_name: parser.send(:extract_merchant_name, text),
      purchase_date: parser.send(:extract_date, text),
      purchase_time: parser.send(:extract_time, text),
      tax: parser.send(:extract_tax, text),
      total: parser.send(:extract_total, text),
      order_items: parser.send(:extract_items, text)
    }
  end

  # Parse attached image
  def parse
    tempfile = Tempfile.new(['receipt', '.jpg'])
    tempfile.binmode
    tempfile.write(@image.download)
    tempfile.rewind

    ocr = RTesseract.new(tempfile.path)
    text = ocr.to_s.strip

    self.class.parse_text(text)
  ensure
    tempfile.close
    tempfile.unlink
  end

  private

  def extract_merchant_name(text)
    # Use first non-empty line as merchant
    text.lines.map(&:strip).find { |l| !l.empty? }
  end

  def extract_date(text)
    date_pattern = /\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})\b/
    match = text.match(date_pattern)
    if match
      month, day, year = match[1].split(/[\/\-\.]/).map(&:to_i)
      Date.new(year, month, day)
    else
      Date.today
    end
  end

  def extract_time(text)
    time_pattern = /\b(\d{1,2}:\d{2}(?:\s?[AP]M)?)\b/i
    match = text.match(time_pattern)
    match ? match[1].strip : Time.now.strftime('%H:%M')
  end

  def extract_tax(text)
    if text =~ /Tax\s+\$?(\d+\.\d{2})/i
      $1.to_f
    else
      nil
    end
  end

  def extract_total(text)
    if text =~ /^(?!Subtotal)(Total|Take-Out Total|Amount Due)\s+\$?(\d+\.\d{2})/i
      $2.to_f
    else
      nil
    end
  end  

  def extract_items(text)
    lines = text.split("\n").map(&:strip)
  
    # Only consider lines up to the first subtotal/total line
    cutoff_index = lines.find_index { |l| l =~ /\b(Subtotal|Take-Out Total|Total)\b/i }
    lines = lines[0...cutoff_index] if cutoff_index
  
    item_lines = lines.select { |l| l =~ /(.*?)(\$?\d+\.\d{2})$/ }
  
    item_lines.map do |line|
      next if line.nil? || line.empty?
    
      if line =~ /(.*?)(\$?\d+\.\d{2})$/
        name_part = $1.strip
        price_part = $2.gsub('$', '').to_f
    
        next if price_part <= 0
        next if name_part =~ /\b(Cash|Cha|Change|Ch i|Tax|Subtotal|Total|Bag)\b/i
    
        { name: name_part, price: price_part, category: infer_category(name_part) }
      end
    end.compact        
  end  

  def infer_category(name)
    case name.downcase
    when /fries/ then 'Side'
    when /pepper|soda|cola|drink/ then 'Beverage'
    when /burger|sandwich|wrap/ then 'Main'
    else 'Other'
    end
  end
end
