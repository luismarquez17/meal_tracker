class CreateMealLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :meal_logs do |t|
      t.date :date
      t.string :meal_type
      t.string :location
      t.decimal :amount, precision: 10, scale: 2
      t.string :note

      t.timestamps
    end
  end
end
