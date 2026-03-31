class StorefrontController < ApplicationController
  def index
    @products = Shopify::ProductCatalog.new.featured
    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
  end

  def show
    @product = Shopify::ProductCatalog.new.find(params[:id])
    return render_not_found if @product.blank?

    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
  end

  private

  def render_not_found
    render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
  end
end
