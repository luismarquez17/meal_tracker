class AddPlaceNameToMealLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :meal_logs, :place_name, :string
  end
end
