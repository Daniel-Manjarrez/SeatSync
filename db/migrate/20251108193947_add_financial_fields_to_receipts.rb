class AddFinancialFieldsToReceipts < ActiveRecord::Migration[8.0]
  def change
    add_column :receipts, :subtotal, :decimal, precision: 8, scale: 2
    add_column :receipts, :total, :decimal, precision: 8, scale: 2
    add_column :receipts, :tip, :decimal, precision: 8, scale: 2
    add_column :receipts, :waiter_name, :string
  end
end
