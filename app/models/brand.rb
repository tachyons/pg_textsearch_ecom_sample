class Brand < ApplicationRecord
  has_many :products, dependent: :nullify

  scope :ordered, -> { order(:name) }

  after_commit :reindex_products_later, if: :saved_change_to_name?

  private

  def reindex_products_later
    ReindexProductsJob.perform_later("Brand", id)
  end
end