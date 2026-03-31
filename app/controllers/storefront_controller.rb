class StorefrontController < ApplicationController
  def index
    @products = Shopify::ProductCatalog.new.featured
    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
  end

  def shop
    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
    @catalog_page = Shopify::ProductCatalog.new.page(
      first: per_page,
      after: params[:after],
      before: params[:before]
    )
  end

  def show
    @product = Shopify::ProductCatalog.new.find(params[:id])
    return render_not_found if @product.blank?

    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
  end

  private

  def per_page
    requested = params[:per].to_i
    return 12 if requested <= 0

    [ requested, 24 ].min
  end

  def render_not_found
    render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
  end
end
