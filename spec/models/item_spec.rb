require 'rails_helper'

RSpec.describe Item, type: :model do
  describe 'validations' do
    it 'requires name' do
      item = Item.new(price: 10.0, category: 'Entrees')
      expect(item).not_to be_valid
      expect(item.errors[:name]).to be_present
    end

    it 'requires price' do
      item = Item.new(name: 'Burger', category: 'Entrees')
      expect(item).not_to be_valid
      expect(item.errors[:price]).to be_present
    end

    it 'requires category' do
      item = Item.new(name: 'Burger', price: 10.0)
      expect(item).not_to be_valid
      expect(item.errors[:category]).to be_present
    end

    it 'requires unique name' do
      Item.create!(name: 'Pizza', price: 12.0, category: 'Entrees')
      duplicate = Item.new(name: 'Pizza', price: 15.0, category: 'Entrees')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'validates price is non-negative' do
      item = Item.new(name: 'Test', price: -5.0, category: 'Entrees')
      expect(item).not_to be_valid
      expect(item.errors[:price]).to be_present
    end

    it 'validates category is in allowed list' do
      item = Item.new(name: 'Test', price: 10.0, category: 'InvalidCategory')
      expect(item).not_to be_valid
      expect(item.errors[:category]).to be_present
    end

    it 'is valid with all required attributes' do
      item = Item.new(name: 'Salad', price: 8.0, category: 'Sides')
      expect(item).to be_valid
    end
  end

  describe 'relationships' do
    it 'has many receipt_items' do
      item = Item.create!(name: 'Burger', price: 10.0, category: 'Entrees')
      receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      receipt.receipt_items.create!(item: item, quantity: 2)
      
      expect(item.receipt_items.count).to eq(1)
    end

    it 'has many receipts through receipt_items' do
      item = Item.create!(name: 'Fries', price: 5.0, category: 'Sides')
      receipt1 = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      receipt2 = Receipt.create!(receipt_date: Date.today, receipt_time: '13:00')
      
      receipt1.receipt_items.create!(item: item, quantity: 1)
      receipt2.receipt_items.create!(item: item, quantity: 2)
      
      expect(item.receipts.count).to eq(2)
    end
  end

  describe 'recipes serialization' do
    it 'stores recipes as JSON' do
      item = Item.create!(
        name: 'Pizza',
        price: 12.0,
        category: 'Entrees',
        recipes: { 'cheese' => 3.0, 'tomato' => 2.0 }
      )
      
      expect(item.recipes).to be_a(Hash)
      expect(item.recipes['cheese']).to eq(3.0)
      expect(item.recipes['tomato']).to eq(2.0)
    end

    it 'can have nil recipes' do
      item = Item.create!(
        name: 'Water',
        price: 1.0,
        category: 'Beverages',
        recipes: nil
      )
      
      expect(item.recipes).to be_nil
    end
  end

  describe 'categories' do
    it 'accepts valid categories' do
      Item::CATEGORIES.each do |category|
        item = Item.new(name: "Test #{category}", price: 10.0, category: category)
        expect(item).to be_valid
      end
    end
  end
end
