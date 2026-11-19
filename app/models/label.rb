class Label < ApplicationRecord
  has_many :product_labels, dependent: :destroy
  has_many :products, through: :product_labels

  scope :ordered, -> { order(:name) }

  after_commit :reindex_products_later, if: :saved_change_to_name?

  private

  def reindex_products_later
    ReindexProductsJob.perform_later("Label", id)
  end
end