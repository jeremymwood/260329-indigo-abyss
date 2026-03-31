class CartController < ApplicationController
  def show
    @line_items = cart.line_items(catalog: Shopify::ProductCatalog.new)
    @total_amount = @line_items.sum(&:subtotal_amount)
    @currency = @line_items.first&.currency_code || "USD"
  end

  def create
    cart.add(product_id: params.require(:product_id), quantity: params[:quantity])
    redirect_back fallback_location: cart_path, notice: "Added to cart."
  end

  def update
    cart.update(product_id: params[:id], quantity: params[:quantity])
    redirect_to cart_path, notice: "Cart updated."
  end

  def destroy
    cart.remove(product_id: params[:id])
    redirect_to cart_path, notice: "Item removed."
  end

  private

  def cart
    @cart ||= SessionCart.new(session: session)
  end
end
