# app/models/receipt.rb
class Receipt < ApplicationRecord
  has_one_attached :image

  validates :receipt_date, presence: true
  validates :receipt_time, presence: true
  serialize :order_items

  # Returns a hash with :date, :time, :items, :subtotal, :tax, :total
  def parsed_data
    return {} unless image.attached?

    text = RTesseract.new(image.download).to_s
    data = ReceiptParser.parse_text(text)

    # Calculate subtotal if total and tax exist
    if data[:total] && data[:tax]
      data[:subtotal] = (data[:total].to_f - data[:tax].to_f).round(2)
    end

    # Only return the item names
    if data[:items] && data[:items].first.is_a?(Hash)
      data[:items] = data[:items].map { |item| item[:name] }
    end    

    # Also optionally include tax/total
    data[:tax] ||= extract_tax(text)
    data[:total] ||= extract_total(text)

    data
  end

  private

  # Optional: fallback methods if parser misses tax or total
  def extract_tax(text)
    if text =~ /Tax\s+(\d+\.\d{2})/i
      $1.to_f
    end
  end

  def extract_total(text)
    if text =~ /(Total|Take-Out Total|Amount Due)\s+(\d+\.\d{2})/i
      $2.to_f
    end
  end
end



