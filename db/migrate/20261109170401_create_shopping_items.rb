class CreateShoppingItems < ActiveRecord::Migration[7.1]
  def change
    create_table :shopping_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, default: "viveres"
      t.decimal :estimated_price, precision: 10, scale: 2, default: 0.0
      t.string :currency, default: "USD"
      t.boolean :completed, default: false, null: false

      t.timestamps
    end

    add_index :shopping_items, [:user_id, :completed]
  end
end
