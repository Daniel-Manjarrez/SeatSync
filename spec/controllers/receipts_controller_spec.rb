require 'rails_helper'

RSpec.describe ReceiptsController, type: :controller do

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @receipts with all receipts ordered by created_at' do
      receipt1 = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '12:00',
        order_items: ['Item 1']
      )
      receipt2 = Receipt.create!(
        receipt_date: Date.today,
        receipt_time: '14:00',
        order_items: ['Item 2']
      )

      get :index
      expect(assigns(:receipts)).to eq([receipt2, receipt1])  # Most recent first
    end
  end

  describe 'GET #show' do
    let(:receipt) do
      Receipt.create!(
        receipt_date: Date.parse('2025-01-15'),
        receipt_time: '14:30',
        order_items: ['Burger', 'Fries']
      )
    end

    it 'assigns the requested receipt to @receipt' do
      get :show, params: { id: receipt.id }
      expect(assigns(:receipt)).to eq(receipt)
    end
  end

  describe 'POST #create' do
    let(:image_path) { Rails.root.join('spec/fixtures/files/sample_receipt.jpg') }
    let(:uploaded_image) { fixture_file_upload(image_path, 'image/jpeg') }

    context 'with valid image upload' do
      before do
        # Mock the parser to return known data (items must be hashes with :text key)
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.parse('2025-01-15'),
          time: '14:30',
          items: [
            { text: 'Burger', ocr_quantity: 1, line_price: 10.0 },
            { text: 'Fries', ocr_quantity: 1, line_price: 5.0 },
            { text: 'Soda', ocr_quantity: 1, line_price: 3.0 }
          ],
          subtotal: 18.0,
          total: 20.0,
          tip: 2.0
        )
        
        # Mock ItemMatcher to return matched items (so the controller flow works)
        allow(ItemMatcher).to receive(:match_all).and_return([])
      end

      it 'creates a new receipt record in the database' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.to change(Receipt, :count).by(1)
      end

      it 'saves the parsed date correctly' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.receipt_date).to eq(Date.parse('2025-01-15'))
      end

      it 'saves the parsed time correctly' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.receipt_time).to eq('14:30')
      end

      it 'saves the parsed order items correctly' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.order_items).to eq(['Burger', 'Fries', 'Soda'])
      end

      it 'attaches the uploaded image to the receipt' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.image).to be_attached
      end

      it 'redirects to receipt show page' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to redirect_to(receipt_path(Receipt.last))
      end

      it 'sets a success flash message' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(flash[:notice]).to match(/Receipt uploaded successfully/)
      end
    end

    context 'without image attachment' do
      it 'does not create a receipt record' do
        expect {
          post :create, params: { receipt: {} }
        }.not_to change(Receipt, :count)
      end

      it 'renders the new template' do
        post :create, params: { receipt: {} }
        expect(response).to render_template(:new)
      end

      it 'sets an error flash message' do
        post :create, params: { receipt: {} }
        expect(flash[:alert]).to eq("Please select a receipt image")
      end
    end

    context 'when saving receipt fails' do
      let(:invalid_receipt) { Receipt.new(receipt_date: nil, receipt_time: nil) }

      before do
        allow(Receipt).to receive(:new).and_return(invalid_receipt)
        allow(invalid_receipt).to receive(:image).and_return(double(attach: true))
        allow(invalid_receipt).to receive(:save).and_return(false)
        allow(invalid_receipt).to receive(:errors).and_return(
          double(full_messages: ['Receipt date is required', 'Receipt time is required'])
        )
      end

      it 'does not create a receipt' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.not_to change(Receipt, :count)
      end

      it 'renders the new template' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to render_template(:new)
      end

      it 'sets error flash message with validation errors' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(flash[:alert]).to include('Failed to save receipt')
      end
    end

    context 'when parsing or matching raises an exception' do
      before do
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_raise(StandardError.new('OCR failed'))
      end

      it 'handles the exception gracefully' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.not_to raise_error
      end

      it 'renders the new template' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to render_template(:new)
      end

      it 'sets error flash message with exception details' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(flash[:alert]).to include('Error processing receipt')
        expect(flash[:alert]).to include('OCR failed')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        post :create, params: { receipt: { image: uploaded_image } }
        expect(Rails.logger).to have_received(:error).at_least(:once)
      end
    end

    context 'when ItemMatcher raises an exception' do
      before do
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.today,
          time: '12:00',
          items: [{ text: 'Burger', ocr_quantity: 1, line_price: 10.0 }],
          subtotal: 10.0,
          total: 10.0,
          tip: 0
        )
        allow(ItemMatcher).to receive(:match_all).and_raise(StandardError.new('Matching failed'))
      end

      it 'handles the exception gracefully' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.not_to raise_error
      end

      it 'renders the new template' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to render_template(:new)
      end
    end

    context 'when transaction fails during receipt update' do
      before do
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.today,
          time: '12:00',
          items: [{ text: 'Burger', ocr_quantity: 1, line_price: 10.0 }],
          subtotal: 10.0,
          total: 10.0,
          tip: 0
        )

        item = Item.create!(name: 'Burger', price: 10.0, category: 'Entrees')
        allow(ItemMatcher).to receive(:match_all).and_return([
          { item: item, quantity: 1, confidence: 1.0, matched_text: 'Burger' }
        ])

        # Mock Receipt#update! to raise an error
        allow_any_instance_of(Receipt).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(Receipt.new))
      end

      it 'handles transaction rollback' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.not_to raise_error
      end

      it 'renders the new template' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to render_template(:new)
      end
    end

    context 'with matched items and receipt items creation' do
      let!(:item) { Item.create!(name: 'Burger', price: 10.0, category: 'Entrees') }

      before do
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.parse('2025-01-15'),
          time: '14:30',
          items: [
            { text: 'Burger', ocr_quantity: 2, line_price: 10.0 }
          ],
          subtotal: 20.0,
          total: 22.0,
          tip: 2.0
        )

        allow(ItemMatcher).to receive(:match_all).and_return([
          { item: item, quantity: 2, confidence: 1.0, matched_text: 'Burger' }
        ])
      end

      it 'creates receipt items' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.to change(ReceiptItem, :count).by(1)
      end

      it 'sets correct quantity on receipt item' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.receipt_items.first.quantity).to eq(2)
      end

      it 'links receipt item to correct item' do
        post :create, params: { receipt: { image: uploaded_image } }
        receipt = Receipt.last
        expect(receipt.receipt_items.first.item).to eq(item)
      end

      it 'includes match count in flash message' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(flash[:notice]).to include('Matched 1 items')
      end
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new receipt to @receipt' do
      get :new
      expect(assigns(:receipt)).to be_a_new(Receipt)
    end
  end
end
