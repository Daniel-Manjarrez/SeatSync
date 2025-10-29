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
        # Mock the parser to return known data
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.parse('2025-01-15'),
          time: '14:30',
          items: ['Burger', 'Fries', 'Soda']
        )
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

      it 'redirects to receipts index page' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to redirect_to(receipts_path)
      end

      it 'sets a success flash message' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(flash[:notice]).to eq("Receipt uploaded successfully")
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
  end
end
