require 'rails_helper'

RSpec.describe Receipt, type: :model do
  describe 'validations' do
    it 'requires receipt_date and receipt_time' do
      receipt = Receipt.new(order_items: [])
      expect(receipt).not_to be_valid
      expect(receipt.errors[:receipt_date]).to be_present
      expect(receipt.errors[:receipt_time]).to be_present
    end

    it 'is valid with all required attributes' do
      receipt = Receipt.new(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: ['Burger', 'Fries']
      )
      expect(receipt).to be_valid
    end
  end

  describe 'image attachment' do
    it 'can have an attached image' do
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: []
      )

      receipt.image.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/SampleReceipt.jpg')),
        filename: 'SampleReceipt.jpg',
        content_type: 'image/jpeg'
      )

      expect(receipt.image).to be_attached
    end
  end

  describe 'integration with OCR parser' do
    it 'parses receipt data from an attached image' do
      receipt = Receipt.create!(
        order_items: [],
        receipt_date: Date.today,
        receipt_time: Time.now
      )
      
      receipt.image.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/SampleReceipt.jpg')),
        filename: 'SampleReceipt.jpg',
        content_type: 'image/jpeg'
      )

      receipt.save!
    
      receipt.parse_receipt_image
    
      expect(receipt.receipt_date).to eq(Date.parse('2018-07-03'))
      expect(receipt.receipt_time).to eq('01:29 PM')
      expect(receipt.order_items.any? { |i| i.include?('French Fries') }).to be true
      expect(receipt.order_items.any? { |i| i.include?('Pepper') }).to be true
    end
  end
end

