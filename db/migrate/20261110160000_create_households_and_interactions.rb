class CreateHouseholdsAndInteractions < ActiveRecord::Migration[7.1]
  def change
    create_table :households do |t|
      t.string :name, null: false
      t.string :invite_code, null: false
      t.bigint :created_by_id, null: false
      t.string :savings_goal_name, default: "Cena especial en familia"
      t.decimal :savings_goal_amount, precision: 10, scale: 2, default: 30.00
      t.timestamps
    end
    add_index :households, :invite_code, unique: true
    add_index :households, :created_by_id

    add_reference :users, :household, foreign_key: true, null: true
    add_column :users, :household_role, :string, default: "member"
    add_column :users, :household_alias, :string

    create_table :meal_reactions do |t|
      t.references :meal_log, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false
      t.timestamps
    end
    add_index :meal_reactions, [:meal_log_id, :user_id, :emoji], unique: true, name: "idx_meal_reactions_unique"

    create_table :cooking_turns do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.string :meal_type, default: "dinner"
      t.string :notes
      t.timestamps
    end
    add_index :cooking_turns, [:household_id, :date, :meal_type], unique: true, name: "idx_cooking_turns_unique"
  end
end
