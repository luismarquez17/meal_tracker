class AddUsdToBsRateToPaymentSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :payment_settings, :usd_to_bs_rate, :decimal, precision: 10, scale: 2, default: 50.00
  end
end
