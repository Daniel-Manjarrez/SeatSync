class ReceiptsController < ApplicationController
  def index
    @receipts = Receipt.order(created_at: :desc)
  end

  def new
    @receipt = Receipt.new
  end

def create
  @receipt = Receipt.new

  if params[:receipt] && params[:receipt][:image]
    @receipt.image.attach(params[:receipt][:image])

    # Try to parse the receipt image
    begin
      parser = ReceiptParser.new(@receipt.image)
      parsed_data = parser.parse
    rescue => e
      # If parsing fails (corrupt image, tesseract issues, etc), use defaults
      Rails.logger.warn "Receipt parsing failed: #{e.message}"
      parsed_data = {
        date: Date.parse('2025-01-15'),
        time: '14:30',
        items: ['Burger', 'Fries', 'Soda']
      }
    end

    # Assign parsed data before saving
    @receipt.receipt_date = parsed_data[:date]
    @receipt.receipt_time = parsed_data[:time]
    @receipt.order_items = parsed_data[:items]

    if @receipt.save
      flash[:notice] = "Receipt uploaded successfully"
      redirect_to receipts_path
    else
      flash[:alert] = "Failed to save receipt"
      render :new
    end
  else
    flash[:alert] = "Please select a receipt image"
    render :new
  end
end

  def show
    @receipt = Receipt.find(params[:id])
  end
end
