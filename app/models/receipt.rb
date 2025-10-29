class Receipt < ApplicationRecord
  has_one_attached :image

  # === SERIALIZATION ===
  serialize :order_items

  # === VALIDATIONS ===
  validates :receipt_date, presence: true
  validates :receipt_time, presence: true

  # === OCR PARSING ===
  def parse_receipt_image
    return unless image.attached?

    parser = ReceiptParser.new(image)
    data = parser.parse

    self.receipt_date = data[:date]
    self.receipt_time = data[:time]
    self.order_items  = data[:items]

    data
  end
end

