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

ActiveRecord::Schema[7.1].define(version: 2025_12_28_221142) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "label", null: false
    t.string "street_address", null: false
    t.string "unit"
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip_code", null: false
    t.text "delivery_instructions"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "is_default"], name: "index_addresses_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "laundry_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "detergent_type", default: 0
    t.integer "water_temperature", default: 1
    t.integer "dry_method", default: 0
    t.boolean "separate_kids_clothing", default: false
    t.boolean "sensitive_skin", default: false
    t.boolean "remove_pet_hair", default: false
    t.boolean "fold_only", default: false
    t.text "personal_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_laundry_preferences_on_user_id", unique: true
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "notification_type", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.boolean "is_read", default: false
    t.jsonb "data"
    t.datetime "sent_at", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_read"], name: "index_notifications_on_is_read"
    t.index ["sent_at"], name: "index_notifications_on_sent_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "order_issues", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "user_id", null: false
    t.integer "issue_type", null: false
    t.text "description", null: false
    t.integer "status", default: 0, null: false
    t.text "resolution_notes"
    t.datetime "resolved_at"
    t.uuid "resolved_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_issues_on_order_id", unique: true
    t.index ["status"], name: "index_order_issues_on_status"
    t.index ["user_id"], name: "index_order_issues_on_user_id"
  end

  create_table "order_timeline_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.integer "event_type", null: false
    t.datetime "timestamp", null: false
    t.text "notes"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_order_timeline_events_on_event_type"
    t.index ["order_id"], name: "index_order_timeline_events_on_order_id"
    t.index ["timestamp"], name: "index_order_timeline_events_on_timestamp"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "address_id", null: false
    t.integer "order_number", null: false
    t.integer "status", default: 0, null: false
    t.integer "order_type", default: 0, null: false
    t.date "pickup_date", null: false
    t.uuid "pickup_time_window_id", null: false
    t.date "delivery_date"
    t.uuid "delivery_time_window_id"
    t.datetime "pickup_actual_time"
    t.datetime "delivery_actual_time"
    t.integer "bag_count"
    t.integer "subtotal_cents"
    t.integer "tax_cents"
    t.integer "total_cents"
    t.jsonb "laundry_preferences_snapshot"
    t.text "special_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_orders_on_address_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["order_type"], name: "index_orders_on_order_type"
    t.index ["pickup_date"], name: "index_orders_on_pickup_date"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "stripe_payment_method_id", null: false
    t.integer "payment_type", null: false
    t.string "last_four", null: false
    t.string "brand"
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_payment_method_id"], name: "index_payment_methods_on_stripe_payment_method_id", unique: true
    t.index ["user_id", "is_default"], name: "index_payment_methods_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "subscription_plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.integer "bags_per_month", null: false
    t.integer "price_cents", null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_subscription_plans_on_is_active"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "subscription_plan_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "bags_used_this_period", default: 0
    t.date "current_period_start"
    t.date "current_period_end"
    t.boolean "auto_recurring", default: false
    t.integer "recurring_day"
    t.uuid "recurring_time_window_id"
    t.string "stripe_subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "time_windows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_time_windows_on_is_active"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.string "device_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "laundry_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "order_issues", "orders"
  add_foreign_key "order_issues", "users"
  add_foreign_key "order_timeline_events", "orders"
  add_foreign_key "orders", "addresses"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_methods", "users"
  add_foreign_key "subscriptions", "subscription_plans"
  add_foreign_key "subscriptions", "users"
end
