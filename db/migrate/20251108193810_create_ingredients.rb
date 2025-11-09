class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false
      t.string :unit, default: 'lbs'

      t.timestamps
    end
    
    add_index :ingredients, :name, unique: true
  end
end
