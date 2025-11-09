require 'rails_helper'

RSpec.describe ReceiptsController, type: :controller do
  let(:image_path) { Rails.root.join('spec/fixtures/files/SampleReceipt.jpg') }
  let(:uploaded_image) { fixture_file_upload(image_path, 'image/jpeg') }

  describe 'POST #create' do
    context 'with valid image upload' do
      before do
        allow_any_instance_of(ReceiptParser).to receive(:parse).and_return(
          date: Date.parse('2025-01-15'),
          time: '14:30',
          items: ['Burger', 'Fries', 'Soda'],
          subtotal: 8.5,
          tax: 0.5,
          total: 9.0
        )
      end

      it 'creates a new receipt with parsed data' do
        expect {
          post :create, params: { receipt: { image: uploaded_image } }
        }.to change(Receipt, :count).by(1)

        receipt = Receipt.last
        expect(receipt.receipt_date).to eq(Date.parse('2025-01-15'))
        expect(receipt.receipt_time).to eq('14:30')
        expect(receipt.order_items).to eq(['Burger', 'Fries', 'Soda'])
        expect(receipt.image).to be_attached
      end

      it 'redirects with a success flash' do
        post :create, params: { receipt: { image: uploaded_image } }
        expect(response).to redirect_to(receipts_path)
        expect(flash[:notice]).to eq('Receipt uploaded successfully')
      end
    end

    context 'without image attachment' do
      it 'does not create a receipt and shows error' do
        expect {
          post :create, params: { receipt: {} }
        }.not_to change(Receipt, :count)

        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('Please select a receipt image')
      end
    end
  end
end
