class CreateUserSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :user_settings do |t|
      t.decimal :benchmark_street_cost, precision: 10, scale: 2, default: 12.00
      t.decimal :monthly_budget, precision: 10, scale: 2, default: 200.00
      t.string :currency_symbol, default: "$"

      t.timestamps
    end
  end
end
