require 'rails_helper'

RSpec.describe Receipt, type: :model do

  # === VALIDATIONS ===
  describe 'validations' do
    it 'requires receipt_date' do
      receipt = Receipt.new(receipt_time: '12:00', order_items: [])
      expect(receipt).not_to be_valid
      expect(receipt.errors[:receipt_date]).to be_present
    end

    it 'requires receipt_time' do
      receipt = Receipt.new(receipt_date: Date.today, order_items: [])
      expect(receipt).not_to be_valid
      expect(receipt.errors[:receipt_time]).to be_present
    end

    it 'is valid with all required attributes' do
      receipt = Receipt.new(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: ['Item 1']
      )
      expect(receipt).to be_valid
    end
  end

  # === ASSOCIATIONS ===
  describe 'image attachment' do
    it 'can have an attached image' do
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: []
      )

      receipt.image.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/sample_receipt.jpg')),
        filename: 'receipt.jpg',
        content_type: 'image/jpeg'
      )

      expect(receipt.image).to be_attached
    end
  end

  # === SERIALIZATION ===
  describe 'order_items serialization' do
    it 'stores and retrieves order items as an array' do
      items = ['Burger', 'Fries', 'Soda']
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '14:30',
        order_items: items
      )

      receipt.reload
      expect(receipt.order_items).to eq(items)
      expect(receipt.order_items).to be_an(Array)
    end
  end
end
