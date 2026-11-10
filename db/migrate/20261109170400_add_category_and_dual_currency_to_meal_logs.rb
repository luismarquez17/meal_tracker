class AddCategoryAndDualCurrencyToMealLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :meal_logs, :category, :string, default: "meal"
    add_column :meal_logs, :currency, :string, default: "USD"
    add_column :meal_logs, :original_amount, :decimal, precision: 10, scale: 2
    add_column :meal_logs, :bcv_rate, :decimal, precision: 10, scale: 2

    add_index :meal_logs, :category
  end
end
