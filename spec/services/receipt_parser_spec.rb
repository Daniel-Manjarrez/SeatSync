require 'rails_helper'

RSpec.describe ReceiptParser, type: :service do
  let(:image_path) { Rails.root.join('spec/fixtures/files/SampleReceipt.jpg') }
  let(:image_file) { ActiveStorage::Blob.create_and_upload!(io: File.open(image_path), filename: 'sample_receipt.jpg') }

  it 'extracts text and parses key data' do
    parser = ReceiptParser.new(image_file)
    result = parser.parse

    expect(result[:date]).to be_a(Date)
    expect(result[:time]).to be_a(String)
    expect(result[:items]).to be_an(Array)
  end
end
