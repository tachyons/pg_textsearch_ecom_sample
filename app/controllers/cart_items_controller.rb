class CartItemsController < ApplicationController
  def create
    @cart = current_cart
    product = Product.find(params[:product_id])
    @cart_item = @cart.add_product(product)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to products_path, notice: "Added to cart" }
    end
  end

  def update
    @cart = current_cart
    @cart_item = @cart.cart_items.find(params[:id])
    @cart_item.update!(quantity: params[:quantity].to_i)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end

  def destroy
    @cart = current_cart
    @cart_item = @cart.cart_items.find(params[:id])
    @cart_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path }
    end
  end
end