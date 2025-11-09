class ReceiptItem < ApplicationRecord
  # Relationships
  belongs_to :receipt
  belongs_to :item
  
  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
end
