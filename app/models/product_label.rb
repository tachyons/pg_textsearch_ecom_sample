class ProductLabel < ApplicationRecord
  belongs_to :product, counter_cache: :labels_count
  belongs_to :label, counter_cache: :products_count

  after_commit :reindex_product, on: [:create, :destroy]

  private

  def reindex_product
    product.refresh_search_text!
  end
end