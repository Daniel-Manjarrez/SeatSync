class AddSubtotalToReceipts < ActiveRecord::Migration[8.0]
  def change
    add_column :receipts, :subtotal, :decimal
  end
end
