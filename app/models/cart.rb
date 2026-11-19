class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def add_product(product, quantity = 1)
    item = cart_items.find_or_initialize_by(product: product)
    item.quantity = (item.quantity || 0) + quantity
    item.save!
    item
  end

  def total_price_cents
    cart_items.sum { |item| item.product.price_cents * item.quantity }
  end

  def total_items
    cart_items.sum(:quantity)
  end
end