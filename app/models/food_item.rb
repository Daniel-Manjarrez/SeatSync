class FoodItem < ApplicationRecord
  belongs_to :receipt, optional: true

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false

  # Categorization logic can be expanded on later
  def category_from_name
    case name.downcase
    when /fries/
      'Side'
    when /dr\s*pepper|soda|cola|drink/
      'Beverage'
    when /burger|chicken|steak|pizza|sandwich/
      'Main'
    else
      'Other'
    end
  end  
end
