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

ActiveRecord::Schema[8.1].define(version: 2026_11_19_044724) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_textsearch"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_brands_on_slug", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "labels", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "color", default: "slate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "products_count", default: 0, null: false
    t.index ["slug"], name: "index_labels_on_slug", unique: true
  end

  create_table "product_labels", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "label_id", null: false
    t.index ["label_id", "product_id"], name: "index_product_labels_on_label_id_and_product_id"
    t.index ["label_id"], name: "index_product_labels_on_label_id"
    t.index ["product_id", "label_id"], name: "index_product_labels_on_product_id_and_label_id", unique: true
    t.index ["product_id"], name: "index_product_labels_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "sku", null: false
    t.text "description"
    t.text "search_text", default: "", null: false
    t.integer "price_cents", null: false
    t.integer "stock_count", default: 0, null: false
    t.decimal "rating_avg", precision: 3, scale: 2, default: "0.0"
    t.integer "popularity_score", default: 0
    t.boolean "active", default: true, null: false
    t.bigint "category_id", null: false
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "labels_count", default: 0, null: false
    t.index ["active", "brand_id"], name: "index_products_on_active_and_brand_id"
    t.index ["active", "category_id"], name: "index_products_on_active_and_category_id"
    t.index ["active", "price_cents"], name: "index_products_on_active_and_price_cents"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["description"], name: "products_active_desc_idx", where: "(active = true)", using: :bm25, with: { text_config: "english", k1: 1.5, b: 0.75 }
    t.index ["name"], name: "products_active_name_idx", where: "(active = true)", using: :bm25, with: { text_config: "english", k1: 1.2, b: 0.75 }
    t.index ["price_cents"], name: "index_products_on_price_cents"
    t.index ["rating_avg"], name: "index_products_on_rating_avg"
    t.index ["search_text"], name: "products_active_search_idx", where: "(active = true)", using: :bm25, with: { text_config: "english", k1: 1.5, b: 0.75 }
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "search_logs", force: :cascade do |t|
    t.string "query", null: false
    t.jsonb "filters_json", default: {}
    t.integer "results_count", default: 0
    t.integer "latency_ms", default: 0
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_search_logs_on_created_at"
    t.index ["query"], name: "index_search_logs_on_query"
    t.index ["user_id"], name: "index_search_logs_on_user_id"
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "product_labels", "labels"
  add_foreign_key "product_labels", "products"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
end
