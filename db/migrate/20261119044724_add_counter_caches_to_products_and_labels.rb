class AddCounterCachesToProductsAndLabels < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :labels_count, :integer, default: 0, null: false
    add_column :labels, :products_count, :integer, default: 0, null: false
  end
end
