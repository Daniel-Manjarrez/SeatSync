class AddTableSizeToReceipts < ActiveRecord::Migration[8.0]
  def change
    add_column :receipts, :table_size, :integer
  end
end
