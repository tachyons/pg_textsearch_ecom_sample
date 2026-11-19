class AddProductBm25Indexes < ActiveRecord::Migration[8.0]
  def change
    # 1. Primary catalog search (partial index for active products only)
    add_index :products, :search_text,
      name: :products_active_search_idx,
      using: :bm25,
      where: "active = true",
      with: { text_config: "english", k1: 1.5, b: 0.75 }

    # 2. Fast autocomplete on product name
    add_index :products, :name,
      name: :products_active_name_idx,
      using: :bm25,
      where: "active = true",
      with: { text_config: "english", k1: 1.2, b: 0.75 }

    # 3. Content-based related products on description
    add_index :products, :description,
      name: :products_active_desc_idx,
      using: :bm25,
      where: "active = true",
      with: { text_config: "english", k1: 1.5, b: 0.75 }
  end
end
