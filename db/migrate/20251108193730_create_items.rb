class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.decimal :price, precision: 8, scale: 2, null: false
      t.string :category
      t.text :recipes

      t.timestamps
    end
    
    add_index :items, :name, unique: true
  end
end
