class Product < ApplicationRecord
  belongs_to :category
  belongs_to :brand
  has_many :product_labels, dependent: :destroy
  has_many :labels, through: :product_labels

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock_count > 0") }

  # Strip tsquery metacharacters before passing user text to prefix search:
  # pg_textsearch 0.1.5 feeds terms to to_tsquery, which raises on : & | ( ) (issue #22).
  def self.search_terms(text)
    text.to_s.gsub(/[^\p{Alnum}\s]/, " ").squish
  end

  # BM25 declarations
  has_bm25 :search_text,
    index: :products_active_search_idx,
    unaccent: true,
    prefix: true

  has_bm25 :name,
    index: :products_active_name_idx,
    unaccent: true,
    prefix: true

  has_bm25 :description,
    index: :products_active_desc_idx

  before_save :sync_search_text

  # Keep search_text updated when labels are attached/removed
  def refresh_search_text!
    update_column(:search_text, build_search_text)
  end

  def related_products(limit: 4)
    return Product.none if description.blank?

    Product.active
           .where.not(id: id)
           .bm25_search(:description, description, index: :products_active_desc_idx)
           .limit(limit)
  end

  private

  def sync_search_text
    self.search_text = build_search_text
  end

  def build_search_text
    [
      name,
      brand&.name,
      category&.name,
      description,
      labels.pluck(:name).join(" "),
      sku
    ].compact_blank.join(" ")
  end
end