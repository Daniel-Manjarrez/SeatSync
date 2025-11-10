class Receipt < ApplicationRecord
  # === ATTACHMENTS ===
  has_one_attached :image

  # === RELATIONSHIPS ===
  has_many :receipt_items, dependent: :destroy
  has_many :items, through: :receipt_items

  # === SERIALIZATION ===
  serialize :order_items  # Keep for backward compatibility

  # === VALIDATIONS ===
  validates :receipt_date, presence: true
  validates :receipt_time, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :table_size, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

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
  
  # === INGREDIENT USAGE ===
  def calculate_ingredient_usage
    ingredient_usage = Hash.new(0)
    
    receipt_items.includes(:item).each do |receipt_item|
      item = receipt_item.item
      quantity_ordered = receipt_item.quantity
      
      # Parse recipes JSON and sum up ingredients
      next unless item.recipes.is_a?(Hash)

      item.recipes.each do |ingredient_name, amount_per_serving|
        next if ingredient_name.blank?

        # Normalize ingredient name by matching existing Ingredient (case-insensitive)
        ing = Ingredient.where('lower(name) = ?', ingredient_name.to_s.downcase).first
        key = ing ? ing.name : ingredient_name.to_s.split.map(&:capitalize).join(' ')

        ingredient_usage[key] += amount_per_serving * quantity_ordered
      end
    end
    
    ingredient_usage
  end
  
  # === CLASS METHODS ===
  def self.ingredient_usage_report(start_date, end_date)
    usage = Hash.new(0)
    
    where(receipt_date: start_date..end_date).includes(receipt_items: :item).find_each do |receipt|
      receipt.calculate_ingredient_usage.each do |ingredient, amount|
        usage[ingredient] += amount
      end
    end
    
    # Ensure keys are normalized to existing Ingredient names where possible
    normalized = {}
    usage.each do |name, amt|
      ing = Ingredient.where('lower(name) = ?', name.to_s.downcase).first
      key = ing ? ing.name : name
      normalized[key] ||= 0
      normalized[key] += amt
    end

    normalized
  end
end

