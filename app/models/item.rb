class Item < ApplicationRecord
  # Relationships
  has_many :receipt_items
  has_many :receipts, through: :receipt_items
  
  # Serialize recipes as JSON
  serialize :recipes, coder: JSON
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  
  # Categories
  CATEGORIES = ['Appetizers', 'Entrees', 'Sides', 'Desserts', 'Beverages'].freeze
  validates :category, inclusion: { in: CATEGORIES }
end
