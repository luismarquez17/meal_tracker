class AddBcvRateFieldsToPaymentSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :payment_settings, :rate_updated_at, :datetime
    add_column :payment_settings, :rate_source, :string, default: "BCV Oficial"
    add_column :payment_settings, :auto_update_rate, :boolean, default: true
  end
end
