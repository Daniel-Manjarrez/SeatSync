class Receipt < ApplicationRecord
  # ActiveStorage attachment for image
  has_one_attached :image

  # Serialize order_items as JSON array
  serialize :order_items, type: Array, coder: JSON
  
  # Note: receipt_date and receipt_time are filled by ReceiptParser after image upload
  # Validation removed to allow initial save before parsing
end
