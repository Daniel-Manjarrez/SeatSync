require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'validations' do
    it 'requires name' do
      ingredient = Ingredient.new(unit: 'oz')
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:name]).to be_present
    end

    it 'requires unit' do
      ingredient = Ingredient.new(name: 'Tomato', unit: nil)
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:unit]).to be_present
    end

    it 'uses default unit when not provided' do
      ingredient = Ingredient.new(name: 'Tomato')
      expect(ingredient.unit).to eq('lbs')
    end

    it 'requires unique name' do
      Ingredient.create!(name: 'Tomato', unit: 'oz')
      duplicate = Ingredient.new(name: 'Tomato', unit: 'lb')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'is valid with all required attributes' do
      ingredient = Ingredient.new(name: 'Cheese', unit: 'oz')
      expect(ingredient).to be_valid
    end
  end

  describe 'database' do
    it 'saves successfully with valid attributes' do
      ingredient = Ingredient.new(name: 'Lettuce', unit: 'oz')
      expect { ingredient.save! }.not_to raise_error
    end
  end
end
