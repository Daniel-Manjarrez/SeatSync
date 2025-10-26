class CreateReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :receipts do |t|
      t.date :receipt_date
      t.string :receipt_time
      t.text :order_items

      t.timestamps
    end
  end
end
