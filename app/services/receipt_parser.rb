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
    {
      date: extract_date(text),
      time: extract_time(text),
      items: extract_items(text)
    }
  ensure
    tempfile.close
    tempfile.unlink
  end

  private

  def extract_date(text)
    # Common receipt date patterns
    date_pattern = /\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b/
    match = text.match(date_pattern)
    match ? Date.parse(match[1]) : Date.today
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
end
