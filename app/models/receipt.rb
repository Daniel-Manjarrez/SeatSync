class Receipt < ApplicationRecord
  # ActiveStorage attachment for image
  has_one_attached :image

  # Validations
  validates :receipt_date, presence: true
  validates :receipt_time, presence: true

  # Serialize order_items as JSON array
  serialize :order_items, type: Array, coder: JSON
end
