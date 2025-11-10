class ReceiptsController < ApplicationController
  def index
    @receipts = Receipt.includes(receipt_items: :item).order(created_at: :desc)
  end

  def new
    @receipt = Receipt.new
  end

def create
  @receipt = Receipt.new(receipt_date: Date.today, receipt_time: Time.now.strftime('%H:%M'))

  if params[:receipt] && params[:receipt][:image]
    @receipt.image.attach(params[:receipt][:image])

    # IMPORTANT: Save receipt first so Active Storage can access the image
    if @receipt.save
      @receipt.reload # Reload to ensure image is accessible
      
      # Now parse the receipt image
      parser = ReceiptParser.new(@receipt.image)
      parsed_data = parser.parse

      # Match OCR items to menu items with subtotal validation
      matched_items = ItemMatcher.match_all(parsed_data[:items], subtotal: parsed_data[:subtotal])

      # Update receipt with parsed data and create receipt items in a transaction
      Receipt.transaction do
        @receipt.update!(
          receipt_date: parsed_data[:date],
          receipt_time: parsed_data[:time],
          subtotal: parsed_data[:subtotal],
          total: parsed_data[:total],
          tip: parsed_data[:tip],
          order_items: parsed_data[:items].map { |i| i[:text] }
        )

        # Create receipt_items for each matched item
        matched_items.each do |match|
          @receipt.receipt_items.create!(
            item: match[:item],
            quantity: match[:quantity]
          )
        end
      end

      flash[:notice] = "Receipt uploaded successfully! Matched #{matched_items.length} items."
      redirect_to @receipt
    else
      flash[:alert] = "Failed to save receipt: #{@receipt.errors.full_messages.join(', ')}"
      render :new
    end
  else
    flash[:alert] = "Please select a receipt image"
    render :new
  end
rescue => e
  Rails.logger.error "Receipt upload failed: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  flash[:alert] = "Error processing receipt: #{e.message}"
  render :new
end

  def show
    @receipt = Receipt.find(params[:id])
  end
end
