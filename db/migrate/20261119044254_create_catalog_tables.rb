class CreateCatalogTables < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.references :parent, foreign_key: { to_table: :categories }
      t.timestamps
    end

    create_table :brands do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.timestamps
    end

    create_table :labels do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :color, default: "slate"
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :sku, null: false, index: { unique: true }
      t.text :description
      t.text :search_text, null: false, default: ""
      t.integer :price_cents, null: false, index: true
      t.integer :stock_count, null: false, default: 0
      t.decimal :rating_avg, precision: 3, scale: 2, default: 0.0, index: true
      t.integer :popularity_score, default: 0
      t.boolean :active, null: false, default: true
      t.references :category, null: false, foreign_key: true
      t.references :brand, null: false, foreign_key: true
      t.timestamps
    end

    create_table :product_labels do |t|
      t.references :product, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.index [ :product_id, :label_id ], unique: true
      t.index [ :label_id, :product_id ]
    end

    # Supporting B-tree indexes for facet filtering & aggregates
    add_index :products, [ :active, :category_id ]
    add_index :products, [ :active, :brand_id ]
    add_index :products, [ :active, :price_cents ]
  end
end
