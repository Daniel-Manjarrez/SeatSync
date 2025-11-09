require 'rails_helper'

RSpec.describe FoodItem, type: :model do
  let(:receipt) { Receipt.create!(receipt_date: Date.today, receipt_time: '12:00', order_items: []) }

  describe 'validations' do
    it 'is valid with name and price' do
      item = FoodItem.new(name: 'French Fries', price: 3.29, receipt: receipt)
      expect(item).to be_valid
    end

    it 'requires a name' do
      item = FoodItem.new(price: 2.50, receipt: receipt)
      expect(item).not_to be_valid
      expect(item.errors[:name]).to include("can't be blank")
    end

    it 'requires a numeric price' do
      item = FoodItem.new(name: 'Soda', price: 'abc', receipt: receipt)
      expect(item).not_to be_valid
      expect(item.errors[:price]).to include('is not a number')
    end
  end

  describe '#category_from_name' do
    it 'infers "Beverage" correctly' do
      item = FoodItem.new(name: 'Dr Pepper', price: 1.0, receipt: receipt)
      expect(item.category_from_name).to eq('Beverage')
    end

    it 'infers "Side" correctly' do
      item = FoodItem.new(name: 'French Fries', price: 2.5, receipt: receipt)
      expect(item.category_from_name).to eq('Side')
    end

    it 'infers "Main" correctly' do
      item = FoodItem.new(name: 'Cheeseburger', price: 5.0, receipt: receipt)
      expect(item.category_from_name).to eq('Main')
    end

    it 'defaults to "Other" for unknown items' do
      item = FoodItem.new(name: 'Mystery Dish', price: 4.0, receipt: receipt)
      expect(item.category_from_name).to eq('Other')
    end

    it 'is case-insensitive' do
      item = FoodItem.new(name: 'sOdA', price: 1.5, receipt: receipt)
      expect(item.category_from_name).to eq('Beverage')
    end
  end

  describe 'associations' do
    it 'belongs to a receipt' do
      item = FoodItem.new(name: 'Fries', price: 2.5, receipt: receipt)
      expect(item.receipt).to eq(receipt)
    end
  end
end
