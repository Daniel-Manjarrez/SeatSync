class ReceiptParser
  def initialize(image)
    @image = image
  end

  def parse
    # STUB: For now, return hardcoded data
    # TODO: Replace with actual OCR/Vision API call
    {
      date: Date.parse('2025-01-15'),
      time: '14:30',
      items: ['Burger', 'Fries', 'Soda']
    }
  end

  private

  def extract_date
    # TODO: Extract from EXIF metadata or OCR
    Date.today
  end

  def extract_time
    # TODO: Extract from EXIF metadata or OCR
    Time.now.strftime('%H:%M')
  end

  def extract_items
    # TODO: Call OCR/Vision API
    []
  end
end
