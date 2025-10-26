class ReceiptsController < ApplicationController
  def index
    @receipts = Receipt.order(created_at: :desc)
  end

  def new
    @receipt = Receipt.new
  end

  def create
    @receipt = Receipt.new

    # Attach uploaded image
    if params[:receipt] && params[:receipt][:image]
      @receipt.image.attach(params[:receipt][:image])

      # Parse the image
      parser = ReceiptParser.new(@receipt.image)
      parsed_data = parser.parse

      # Assign parsed data
      @receipt.receipt_date = parsed_data[:date]
      @receipt.receipt_time = parsed_data[:time]
      @receipt.order_items = parsed_data[:items]

      if @receipt.save
        flash[:notice] = "Receipt uploaded successfully!"
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
