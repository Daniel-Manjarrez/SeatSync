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

    it 'validates total is non-negative' do
      receipt = Receipt.new(
        receipt_date: Date.today,
        receipt_time: '12:00',
        total: -10.0
      )
      expect(receipt).not_to be_valid
      expect(receipt.errors[:total]).to be_present
    end

    it 'validates table_size is a positive integer' do
      receipt = Receipt.new(
        receipt_date: Date.today,
        receipt_time: '12:00',
        table_size: -1
      )
      expect(receipt).not_to be_valid
      expect(receipt.errors[:table_size]).to be_present
    end

    it 'allows nil total and table_size' do
      receipt = Receipt.new(
        receipt_date: Date.today,
        receipt_time: '12:00',
        total: nil,
        table_size: nil
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
      
      # Mock the parser to return known data
      allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
        date: Date.parse('2018-07-03'),
        time: '01:29 PM',
        items: [
          { text: 'French Fries', ocr_quantity: 2, line_price: 6.0 },
          { text: 'Pepper Steak', ocr_quantity: 1, line_price: 15.0 }
        ],
        subtotal: 21.0,
        total: 23.0,
        tip: 2.0
      )
    
      receipt.parse_receipt_image
    
      expect(receipt.receipt_date).to eq(Date.parse('2018-07-03'))
      expect(receipt.receipt_time).to eq('01:29 PM')
      expect(receipt.order_items).to include('French Fries')
      expect(receipt.order_items).to include('Pepper Steak')
    end

    it 'returns nil when no image is attached' do
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00'
      )
      
      result = receipt.parse_receipt_image
      expect(result).to be_nil
    end
  end

  describe 'ingredient usage calculations' do
    let!(:ingredient1) { Ingredient.create!(name: 'Tomato', unit: 'oz') }
    let!(:ingredient2) { Ingredient.create!(name: 'Cheese', unit: 'oz') }
    let!(:item1) { Item.create!(name: 'Pizza', price: 12.0, category: 'Entrees', recipes: { 'tomato' => 2.0, 'cheese' => 3.0 }) }
    let!(:item2) { Item.create!(name: 'Salad', price: 8.0, category: 'Sides', recipes: { 'tomato' => 1.0 }) }

    describe '#calculate_ingredient_usage' do
      it 'calculates ingredient usage from receipt items' do
        receipt = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00',
          total: 20.0
        )
        receipt.receipt_items.create!(item: item1, quantity: 2)
        receipt.receipt_items.create!(item: item2, quantity: 1)

        usage = receipt.calculate_ingredient_usage

        expect(usage['Tomato']).to eq(5.0) # (2*2) + (1*1)
        expect(usage['Cheese']).to eq(6.0) # (3*2)
      end

      it 'handles items without recipes' do
        item_no_recipe = Item.create!(name: 'Water', price: 1.0, category: 'Beverages', recipes: nil)
        receipt = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00'
        )
        receipt.receipt_items.create!(item: item_no_recipe, quantity: 1)

        usage = receipt.calculate_ingredient_usage
        expect(usage).to eq({})
      end

      it 'skips blank ingredient names' do
        item_blank = Item.create!(name: 'Test', price: 5.0, category: 'Appetizers', recipes: { '' => 1.0, 'tomato' => 2.0 })
        receipt = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00'
        )
        receipt.receipt_items.create!(item: item_blank, quantity: 1)

        usage = receipt.calculate_ingredient_usage
        expect(usage.keys).not_to include('')
        expect(usage['Tomato']).to eq(2.0)
      end

      it 'normalizes ingredient names to existing ingredients' do
        receipt = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00'
        )
        receipt.receipt_items.create!(item: item1, quantity: 1)

        usage = receipt.calculate_ingredient_usage
        # Should normalize 'tomato' to 'Tomato' based on existing ingredient
        expect(usage.keys).to include('Tomato')
      end
    end

    describe '.ingredient_usage_report' do
      it 'aggregates ingredient usage across multiple receipts' do
        receipt1 = Receipt.create!(
          receipt_date: Date.parse('2025-01-15'),
          receipt_time: '12:00',
          total: 20.0
        )
        receipt1.receipt_items.create!(item: item1, quantity: 2)

        receipt2 = Receipt.create!(
          receipt_date: Date.parse('2025-01-16'),
          receipt_time: '13:00',
          total: 8.0
        )
        receipt2.receipt_items.create!(item: item2, quantity: 3)

        usage = Receipt.ingredient_usage_report(Date.parse('2025-01-15'), Date.parse('2025-01-16'))

        expect(usage['Tomato']).to eq(7.0) # (2*2) + (1*3)
        expect(usage['Cheese']).to eq(6.0) # (3*2)
      end

      it 'filters by date range' do
        receipt_in_range = Receipt.create!(
          receipt_date: Date.parse('2025-01-15'),
          receipt_time: '12:00'
        )
        receipt_in_range.receipt_items.create!(item: item1, quantity: 1)

        receipt_out_of_range = Receipt.create!(
          receipt_date: Date.parse('2025-01-20'),
          receipt_time: '12:00'
        )
        receipt_out_of_range.receipt_items.create!(item: item1, quantity: 10)

        usage = Receipt.ingredient_usage_report(Date.parse('2025-01-15'), Date.parse('2025-01-16'))

        expect(usage['Tomato']).to eq(2.0) # Only from receipt_in_range
        expect(usage['Cheese']).to eq(3.0) # Only from receipt_in_range
      end

      it 'returns empty hash when no receipts in date range' do
        usage = Receipt.ingredient_usage_report(Date.parse('2025-01-01'), Date.parse('2025-01-02'))
        expect(usage).to eq({})
      end

      it 'normalizes ingredient names in the report' do
        receipt = Receipt.create!(
          receipt_date: Date.today,
          receipt_time: '12:00'
        )
        receipt.receipt_items.create!(item: item1, quantity: 1)

        usage = Receipt.ingredient_usage_report(Date.today, Date.today)
        expect(usage.keys).to include('Tomato')
        expect(usage.keys).to include('Cheese')
      end
    end
  end

  describe 'relationships' do
    it 'has many receipt_items' do
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00'
      )
      item = Item.create!(name: 'Test Item', price: 10.0, category: 'Entrees')
      
      receipt.receipt_items.create!(item: item, quantity: 2)
      
      expect(receipt.receipt_items.count).to eq(1)
      expect(receipt.receipt_items.first.item).to eq(item)
    end

    it 'destroys associated receipt_items when deleted' do
      receipt = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00'
      )
      item = Item.create!(name: 'Test Item', price: 10.0, category: 'Entrees')
      receipt.receipt_items.create!(item: item, quantity: 1)

      expect { receipt.destroy }.to change(ReceiptItem, :count).by(-1)
    end
  end
end

