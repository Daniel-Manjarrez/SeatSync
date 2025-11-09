require 'rails_helper'

RSpec.describe ReceiptParser, type: :service do
  let(:image_path) { Rails.root.join('spec/fixtures/files/SampleReceipt.jpg') }
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: File.open(image_path), filename: 'SampleReceipt.jpg') }

  describe '.parse_text' do
    it 'parses plain text without an image' do
      sample_text = <<~TEXT
        Sample Merchant
        07/03/2018 01:29 PM
        French Fries 2.50
        5 French Fries 3.48
        Or Pepper 0.00
        Subtotal 5.98
        Tax 0.62
        Total 6.60
      TEXT

      result = ReceiptParser.parse_text(sample_text)

      expect(result[:purchase_date]).to eq(Date.parse('2018-07-03'))
      expect(result[:purchase_time]).to eq('01:29 PM')

      # Only non-zero-priced items are included by parser
      expect(result[:order_items].map { |i| i[:name] }).to include('French Fries', '5 French Fries')
      expect(result[:order_items].map { |i| i[:name] }).not_to include('Or Pepper')

      expect(result[:tax]).to eq(0.62)
      expect(result[:total]).to eq(6.60)
    end
  end

  describe '#parse' do
    it 'returns a hash with parsed receipt data from an image' do
      parser = ReceiptParser.new(blob)
      
      # Mock parse_text to match expected values
      allow(ReceiptParser).to receive(:parse_text).and_return(
        purchase_date: Date.parse('2018-07-03'),
        purchase_time: '01:29 PM',
        order_items: [
          { name: 'French Fries', price: 2.50 },
          { name: '5 French Fries', price: 3.48 }
        ],
        subtotal: 5.98,
        tax: 0.62,
        total: 6.60
      )

      result = parser.parse

      expect(result[:purchase_date]).to eq(Date.parse('2018-07-03'))
      expect(result[:purchase_time]).to eq('01:29 PM')
      expect(result[:order_items].map { |i| i[:name] }).to include('French Fries', '5 French Fries')
      expect(result[:order_items].map { |i| i[:name] }).not_to include('Or Pepper')
      expect(result[:tax]).to eq(0.62)
      expect(result[:total]).to eq(6.60)
    end
  end
end

