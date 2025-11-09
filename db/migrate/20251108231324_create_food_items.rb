class CreateFoodItems < ActiveRecord::Migration[8.0]
  def change
    create_table :food_items do |t|
      t.string :name
      t.decimal :price
      t.string :category
      t.references :receipt, foreign_key: true

      t.timestamps
    end
  end
end
