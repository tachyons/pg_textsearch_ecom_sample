class Category < ApplicationRecord
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id", dependent: :nullify
  belongs_to :parent, class_name: "Category", optional: true
  has_many :products, dependent: :nullify

  scope :roots, -> { where(parent_id: nil).order(:position, :name) }
  scope :ordered, -> { order(:position, :name) }
end
