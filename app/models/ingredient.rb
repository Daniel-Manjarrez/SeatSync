class Ingredient < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :unit, presence: true
end
