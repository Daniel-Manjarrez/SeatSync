class CreateReceiptItems < ActiveRecord::Migration[8.0]
  def change
    create_table :receipt_items do |t|
      t.references :receipt, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false

      t.timestamps
    end
    
    add_index :receipt_items, [:receipt_id, :item_id]
  end
end
