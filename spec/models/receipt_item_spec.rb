require 'rails_helper'

RSpec.describe ReceiptItem, type: :model do
  describe 'validations' do
    let(:receipt) { Receipt.create!(receipt_date: Date.today, receipt_time: '12:00') }
    let(:item) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees') }

    it 'uses default quantity of 1 when not provided' do
      receipt_item = ReceiptItem.new(receipt: receipt, item: item)
      expect(receipt_item.quantity).to eq(1)
    end

    it 'validates quantity is positive' do
      receipt_item = ReceiptItem.new(receipt: receipt, item: item, quantity: 0)
      expect(receipt_item).not_to be_valid
      expect(receipt_item.errors[:quantity]).to be_present
    end

    it 'validates quantity is positive (negative)' do
      receipt_item = ReceiptItem.new(receipt: receipt, item: item, quantity: -1)
      expect(receipt_item).not_to be_valid
      expect(receipt_item.errors[:quantity]).to be_present
    end

    it 'validates quantity is an integer' do
      receipt_item = ReceiptItem.new(receipt: receipt, item: item, quantity: 2.5)
      expect(receipt_item).not_to be_valid
      expect(receipt_item.errors[:quantity]).to be_present
    end

    it 'is valid with all required attributes' do
      receipt_item = ReceiptItem.new(receipt: receipt, item: item, quantity: 2)
      expect(receipt_item).to be_valid
    end
  end

  describe 'relationships' do
    it 'belongs to receipt' do
      receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      item = Item.create!(name: 'Fries', price: 5.0, category: 'Sides')
      receipt_item = ReceiptItem.create!(receipt: receipt, item: item, quantity: 1)
      
      expect(receipt_item.receipt).to eq(receipt)
    end

    it 'belongs to item' do
      receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      item = Item.create!(name: 'Soda', price: 3.0, category: 'Beverages')
      receipt_item = ReceiptItem.create!(receipt: receipt, item: item, quantity: 1)
      
      expect(receipt_item.item).to eq(item)
    end

    it 'requires receipt association' do
      item = Item.create!(name: 'Burger', price: 10.0, category: 'Entrees')
      receipt_item = ReceiptItem.new(item: item, quantity: 1)
      
      # Database foreign key constraint will prevent saving without receipt
      expect { receipt_item.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'requires item association' do
      receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      receipt_item = ReceiptItem.new(receipt: receipt, quantity: 1)
      
      # Database foreign key constraint will prevent saving without item
      expect { receipt_item.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe 'database' do
    it 'saves successfully with valid attributes' do
      receipt = Receipt.create!(receipt_date: Date.today, receipt_time: '12:00')
      item = Item.create!(name: 'Salad', price: 8.0, category: 'Sides')
      receipt_item = ReceiptItem.new(receipt: receipt, item: item, quantity: 3)
      
      expect { receipt_item.save! }.not_to raise_error
    end
  end
end
