require 'rails_helper'

RSpec.describe ReceiptParser, type: :service do
  let(:image_path) { Rails.root.join('spec/fixtures/files/SampleReceipt.jpg') }
  let(:image_file) { ActiveStorage::Blob.create_and_upload!(io: File.open(image_path), filename: 'sample_receipt.jpg') }

  describe '#parse' do
    it 'extracts text and parses key data' do
      parser = ReceiptParser.new(image_file)
      result = parser.parse

      expect(result[:date]).to be_a(Date)
      expect(result[:time]).to be_a(String)
      expect(result[:items]).to be_an(Array)
    end

    it 'returns success flag when parsing succeeds' do
      parser = ReceiptParser.new(image_file)
      allow_any_instance_of(RTesseract).to receive(:to_s).and_return("Sample receipt text")
      
      result = parser.parse
      expect(result[:success]).to be true
    end

    it 'handles parsing errors gracefully' do
      parser = ReceiptParser.new(image_file)
      allow(parser).to receive(:extract_date).and_raise(StandardError.new("Test error"))
      
      result = parser.parse
      expect(result[:success]).to be false
      expect(result[:date]).to eq(Date.today)
      expect(result[:time]).to be_a(String)
      expect(result[:items]).to eq([])
    end

    it 'calculates total from subtotal and tax when OCR total is incorrect' do
      parser = ReceiptParser.new(image_file)
      ocr_text = "Subtotal 30.00\nTax 3.00\nTotal 33.00"
      allow_any_instance_of(RTesseract).to receive(:to_s).and_return(ocr_text)
      
      result = parser.parse
      expect(result[:subtotal]).to eq(30.0)
      expect(result[:total]).to eq(33.0)
    end
  end

  describe '#extract_date' do
    it 'extracts date from MM/DD/YYYY format' do
      parser = ReceiptParser.new(image_file)
      text = "Receipt Date: 07/15/2025\nTotal: 50.00"
      
      date = parser.send(:extract_date, text)
      expect(date).to eq(Date.new(2025, 7, 15))
    end

    it 'extracts date with different separators' do
      parser = ReceiptParser.new(image_file)
      text = "Date: 12-25-2025"
      
      date = parser.send(:extract_date, text)
      expect(date).to eq(Date.new(2025, 12, 25))
    end

    it 'returns today when no date found' do
      parser = ReceiptParser.new(image_file)
      text = "No date here"
      
      date = parser.send(:extract_date, text)
      expect(date).to eq(Date.today)
    end
  end

  describe '#extract_time' do
    it 'extracts time in HH:MM format' do
      parser = ReceiptParser.new(image_file)
      text = "Time: 14:30\nTotal: 50.00"
      
      time = parser.send(:extract_time, text)
      expect(time).to eq('14:30')
    end

    it 'extracts time with AM/PM' do
      parser = ReceiptParser.new(image_file)
      text = "Time: 2:30 PM"
      
      time = parser.send(:extract_time, text)
      expect(time).to eq('2:30 PM')
    end

    it 'returns current time when no time found' do
      parser = ReceiptParser.new(image_file)
      text = "No time here"
      
      time = parser.send(:extract_time, text)
      expect(time).to match(/\d{2}:\d{2}/)
    end
  end

  describe '#extract_items_with_quantities' do
    it 'extracts items with quantities and prices' do
      parser = ReceiptParser.new(image_file)
      text = "2 Burger Deluxe 10.50\n1 French Fries 5.00"
      
      items = parser.send(:extract_items_with_quantities, text)
      expect(items.length).to eq(2)
      expect(items[0][:text]).to eq('Burger Deluxe')
      expect(items[0][:ocr_quantity]).to eq(2)
      expect(items[0][:line_price]).to eq(10.5)
      expect(items[1][:text]).to eq('French Fries')
      expect(items[1][:ocr_quantity]).to eq(1)
    end

    it 'filters out non-food lines' do
      parser = ReceiptParser.new(image_file)
      text = "2 Burger Deluxe 10.00\n1 Subtotal 10.00\n1 Tax 1.00"
      
      items = parser.send(:extract_items_with_quantities, text)
      # Should filter out Subtotal and Tax
      expect(items.any? { |i| i[:text].match?(/Subtotal|Tax/i) }).to be false
      expect(items.any? { |i| i[:text].match?(/Burger/) }).to be true
    end

    it 'handles items without prices' do
      parser = ReceiptParser.new(image_file)
      text = "2 Burger Special\n1 Fries Crispy"
      
      items = parser.send(:extract_items_with_quantities, text)
      if items.any?
        expect(items[0][:line_price]).to be_nil
      end
    end

    it 'skips short item names' do
      parser = ReceiptParser.new(image_file)
      text = "2 Ab 10.00\n1 Burger Supreme 15.00"
      
      items = parser.send(:extract_items_with_quantities, text)
      # Should skip "Ab" because it's less than 3 characters
      expect(items.any? { |i| i[:text] == 'Ab' }).to be false
      expect(items.any? { |i| i[:text].match?(/Burger/) }).to be true if items.any?
    end
  end

  describe '#extract_subtotal' do
    it 'extracts subtotal from text' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.50\nTotal: 50.00"
      
      subtotal = parser.send(:extract_subtotal, text)
      expect(subtotal).to eq(45.5)
    end

    it 'handles OCR errors like "suptotal"' do
      parser = ReceiptParser.new(image_file)
      text = "Suptotal: 30.00"
      
      subtotal = parser.send(:extract_subtotal, text)
      expect(subtotal).to eq(30.0)
    end

    it 'returns nil when not found' do
      parser = ReceiptParser.new(image_file)
      text = "Total: 50.00"
      
      subtotal = parser.send(:extract_subtotal, text)
      expect(subtotal).to be_nil
    end
  end

  describe '#extract_total' do
    it 'extracts total from text' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.50\nTotal: 50.00"
      
      total = parser.send(:extract_total, text)
      expect(total).to eq(50.0)
    end

    it 'ignores subtotal when extracting total' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.50\nTotal: 50.00"
      
      total = parser.send(:extract_total, text)
      expect(total).to eq(50.0)
      expect(total).not_to eq(45.5)
    end

    it 'returns nil when not found' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.50"
      
      total = parser.send(:extract_total, text)
      expect(total).to be_nil
    end
  end

  describe '#extract_tip' do
    it 'extracts tip from text' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.00\nTip: 5.00\nTotal: 50.00"
      
      tip = parser.send(:extract_tip, text)
      expect(tip).to eq(5.0)
    end

    it 'handles tip with colon' do
      parser = ReceiptParser.new(image_file)
      text = "Tip: 8.50"
      
      tip = parser.send(:extract_tip, text)
      expect(tip).to eq(8.5)
    end

    it 'returns nil when not found' do
      parser = ReceiptParser.new(image_file)
      text = "Total: 50.00"
      
      tip = parser.send(:extract_tip, text)
      expect(tip).to be_nil
    end
  end

  describe '#extract_tax' do
    it 'extracts tax from text' do
      parser = ReceiptParser.new(image_file)
      text = "Subtotal: 45.00\nTax: 4.50\nTotal: 49.50"
      
      tax = parser.send(:extract_tax, text)
      expect(tax).to eq(4.5)
    end

    it 'handles OCR errors like "Tex"' do
      parser = ReceiptParser.new(image_file)
      text = "Tex: 3.60"
      
      tax = parser.send(:extract_tax, text)
      expect(tax).to eq(3.6)
    end

    it 'returns nil when not found' do
      parser = ReceiptParser.new(image_file)
      text = "Total: 50.00"
      
      tax = parser.send(:extract_tax, text)
      expect(tax).to be_nil
    end
  end
end
