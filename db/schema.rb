# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_11_10_160000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cooking_turns", force: :cascade do |t|
    t.integer "household_id", null: false
    t.integer "user_id", null: false
    t.date "date", null: false
    t.string "meal_type", default: "dinner"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id", "date", "meal_type"], name: "idx_cooking_turns_unique", unique: true
    t.index ["household_id"], name: "index_cooking_turns_on_household_id"
    t.index ["user_id"], name: "index_cooking_turns_on_user_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "name", null: false
    t.string "invite_code", null: false
    t.bigint "created_by_id", null: false
    t.string "savings_goal_name", default: "Cena especial en familia"
    t.decimal "savings_goal_amount", precision: 10, scale: 2, default: "30.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_households_on_created_by_id"
    t.index ["invite_code"], name: "index_households_on_invite_code", unique: true
  end

  create_table "meal_logs", force: :cascade do |t|
    t.date "date"
    t.string "meal_type"
    t.string "location"
    t.decimal "amount", precision: 10, scale: 2
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "place_name"
    t.integer "user_id"
    t.string "category", default: "meal"
    t.string "currency", default: "USD"
    t.decimal "original_amount", precision: 10, scale: 2
    t.decimal "bcv_rate", precision: 10, scale: 2
    t.index ["category"], name: "index_meal_logs_on_category"
    t.index ["user_id"], name: "index_meal_logs_on_user_id"
  end

  create_table "meal_reactions", force: :cascade do |t|
    t.integer "meal_log_id", null: false
    t.integer "user_id", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_log_id", "user_id", "emoji"], name: "idx_meal_reactions_unique", unique: true
    t.index ["meal_log_id"], name: "index_meal_reactions_on_meal_log_id"
    t.index ["user_id"], name: "index_meal_reactions_on_user_id"
  end

  create_table "payment_settings", force: :cascade do |t|
    t.string "pago_movil_bank"
    t.string "pago_movil_phone"
    t.string "pago_movil_id_number"
    t.string "pago_movil_holder_name"
    t.string "binance_pay_id"
    t.string "binance_email"
    t.string "binance_usdt_address"
    t.string "binance_network", default: "TRC20"
    t.decimal "monthly_price_usd", precision: 10, scale: 2, default: "2.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "usd_to_bs_rate", precision: 10, scale: 2, default: "50.0"
    t.datetime "rate_updated_at"
    t.string "rate_source", default: "BCV Oficial"
    t.boolean "auto_update_rate", default: true
  end

  create_table "payments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "2.0", null: false
    t.string "payment_method", null: false
    t.string "reference_number", null: false
    t.string "status", default: "pending", null: false
    t.text "notes"
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_payments_on_approved_by_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "user_settings", force: :cascade do |t|
    t.decimal "benchmark_street_cost", precision: 10, scale: 2, default: "12.0"
    t.decimal "monthly_budget", precision: 10, scale: 2, default: "200.0"
    t.string "currency_symbol", default: "$"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_user_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.string "password_digest"
    t.string "google_uid"
    t.string "avatar_url"
    t.boolean "admin", default: false, null: false
    t.string "subscription_status", default: "active"
    t.datetime "subscription_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "household_id"
    t.string "household_role", default: "member"
    t.string "household_alias"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid"
    t.index ["household_id"], name: "index_users_on_household_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cooking_turns", "households"
  add_foreign_key "cooking_turns", "users"
  add_foreign_key "meal_logs", "users"
  add_foreign_key "meal_reactions", "meal_logs"
  add_foreign_key "meal_reactions", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "user_settings", "users"
  add_foreign_key "users", "households"
end
