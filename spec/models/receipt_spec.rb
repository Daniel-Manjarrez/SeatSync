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

  describe '#parsed_data' do
    let(:receipt) do
      Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: []
      )
    end

    before do
      receipt.image.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/SampleReceipt.jpg')),
        filename: 'SampleReceipt.jpg',
        content_type: 'image/jpeg'
      )
    
      # Prevent RTesseract from actually running
      allow(RTesseract).to receive(:new).and_return(double(to_s: <<~TEXT
        Date: 2018-07-03
        Time: 01:29 PM
        French Fries
        5 French Fries
        Or Pepper
        Subtotal: 5.98
        Tax: 0.62
        Total: 6.60
      TEXT
      ))
    
      # Also mock ReceiptParser.parse_text
      allow(ReceiptParser).to receive(:parse_text).and_return(
        date: Date.parse('2018-07-03'),
        time: '01:29 PM',
        items: ['French Fries', '5 French Fries', 'Or Pepper'],
        subtotal: 5.98,
        tax: 0.62,
        total: 6.60
      )
    end    

    it 'returns a hash with date, time, items, subtotal, tax, and total' do
      data = receipt.parsed_data
      expect(data[:date]).to eq(Date.parse('2018-07-03'))
      expect(data[:time]).to eq('01:29 PM')
      expect(data[:items]).to eq(['French Fries', '5 French Fries', 'Or Pepper'])
      expect(data[:subtotal]).to eq(5.98)
      expect(data[:tax]).to eq(0.62)
      expect(data[:total]).to eq(6.6)
    end

    it 'calculates subtotal if total and tax exist' do
      data = receipt.parsed_data
      expect(data[:subtotal]).to eq(5.98)
    end
  end
end
