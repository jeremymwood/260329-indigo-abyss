class StorefrontController < ApplicationController
  def index
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @products = catalog.featured
    @shopify_connected = client.configured?
    set_storefront_notice(client)
  end

  def shop
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @shopify_connected = client.configured?
    @categories = Shopify::ProductCatalog::SUPPORTED_CATEGORIES
    @selected_category = params[:category].to_s.presence
    @catalog_page = catalog.page(
      first: per_page,
      after: params[:after],
      before: params[:before],
      category: @selected_category
    )
    set_storefront_notice(client)
  end

  def designer
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @designer_slug = params[:slug].to_s
    @designer_name = Shopify::ProductCatalog::SUPPORTED_DESIGNERS[@designer_slug] || @designer_slug.tr("-", " ").split.map(&:capitalize).join(" ")
    @categories = Shopify::ProductCatalog::SUPPORTED_CATEGORIES
    @selected_category = params[:category].to_s.presence
    @shopify_connected = client.configured?

    @catalog_page = catalog.page(
      first: per_page,
      after: params[:after],
      before: params[:before],
      category: @selected_category,
      designer: @designer_slug
    )

    set_storefront_notice(client)
  end

  def show
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @product = catalog.find(params[:id])
    return render_not_found if @product.blank?

    @shopify_connected = client.configured?
    set_storefront_notice(client)
  end

  private

  def per_page
    requested = params[:per].to_i
    return 12 if requested <= 0

    [ requested, 24 ].min
  end

  def set_storefront_notice(client)
    return if !client.configured? || client.last_error.blank?

    flash.now[:alert] = "We couldn't load live Shopify data right now, so we're showing showcase products."
  end

  def render_not_found
    render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
  end
end
