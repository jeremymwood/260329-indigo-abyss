class StorefrontController < ApplicationController
  def index
    @products = Shopify::ProductCatalog.new.featured
    @shopify_connected = ENV["SHOPIFY_STORE_DOMAIN"].present? && ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"].present?
  end
end
