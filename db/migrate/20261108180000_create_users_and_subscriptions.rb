class CreateUsersAndSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.string :password_digest
      t.string :google_uid
      t.string :avatar_url
      t.boolean :admin, default: false, null: false
      t.string :subscription_status, default: "active"
      t.datetime :subscription_expires_at
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :google_uid

    create_table :payment_settings do |t|
      t.string :pago_movil_bank
      t.string :pago_movil_phone
      t.string :pago_movil_id_number
      t.string :pago_movil_holder_name
      t.string :binance_pay_id
      t.string :binance_email
      t.string :binance_usdt_address
      t.string :binance_network, default: "TRC20"
      t.decimal :monthly_price_usd, precision: 10, scale: 2, default: 2.00
      t.timestamps
    end

    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, default: 2.00, null: false
      t.string :payment_method, null: false # 'pago_movil', 'binance'
      t.string :reference_number, null: false
      t.string :status, default: "pending", null: false # 'pending', 'approved', 'rejected'
      t.text :notes
      t.datetime :approved_at
      t.bigint :approved_by_id
      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :approved_by_id

    add_reference :meal_logs, :user, foreign_key: true, null: true
    add_reference :user_settings, :user, foreign_key: true, null: true
  end
end
