class StorefrontController < ApplicationController
  DESIGNER_DESCRIPTIONS = {
    "oni-denim" => "A label shrouded in mystery, ONI Denim of Okayama is one of the most prestigious denim labels in the world. The brand has garnered a cult-following for their signature slub denim, which is crafted in small-batches by a single party on a single shuttle loom in Japan.",
    "iron-heart" => "Built for heavy wear and hard fades, Iron Heart is known for ultra-durable Japanese denim, precise construction, and timeless workwear silhouettes with premium hardware throughout.",
    "samurai-jeans" => "Samurai Jeans blends heritage Japanese craftsmanship with bold character fabrics, offering expressive textures, rich indigo tones, and unmistakable old-world detailing.",
    "studio-dartisan" => "One of Osaka's original repro labels, Studio D'Artisan is revered for classic cuts, vintage-inspired construction, and nuanced fabrics woven for long-term patina and depth."
  }.freeze

  SIZE_OPTIONS = %w[28 29 30 31 32 33 34 36 38 40].freeze
  SORT_OPTIONS = [
    [ "Featured", "featured" ],
    [ "Best selling", "best-selling" ],
    [ "Alphabetically, A-Z", "alpha-asc" ],
    [ "Alphabetically, Z-A", "alpha-desc" ],
    [ "Price, low to high", "price-asc" ],
    [ "Price, high to low", "price-desc" ],
    [ "Date, old to new", "date-asc" ],
    [ "Date, new to old", "date-desc" ]
  ].freeze

  def index
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @products = catalog.featured
    @shopify_connected = client.configured?
    set_storefront_notice(client)
  end

  def shop
    load_shop_page(selected_category: selected_category_from_params)
  end

  def category
    load_shop_page(selected_category: params[:category])
    render :shop
  end

  def designer
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @designer_slug = params[:slug].to_s
    @designer_name = Shopify::ProductCatalog::SUPPORTED_DESIGNERS[@designer_slug] || @designer_slug.tr("-", " ").split.map(&:capitalize).join(" ")
    @designer_description = DESIGNER_DESCRIPTIONS[@designer_slug] || "Explore curated #{@designer_name} products selected for fit, fabric character, and long-term wear."
    @categories = Shopify::ProductCatalog::SUPPORTED_CATEGORIES
    @selected_category = selected_category_from_params
    @shopify_connected = client.configured?

    set_facet_state(catalog: catalog, selected_category: @selected_category, designer: @designer_slug)

    @catalog_page = catalog.page(
      first: per_page,
      after: params[:after],
      before: params[:before],
      category: @selected_category,
      designer: @designer_slug,
      availability: @facet_availability,
      sizes: @facet_selected_sizes,
      price_min: @facet_price_min,
      price_max: @facet_price_max,
      sort_by: @facet_sort_by
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

  def load_shop_page(selected_category:)
    client = Shopify::StorefrontClient.new
    catalog = Shopify::ProductCatalog.new(client: client)

    @shopify_connected = client.configured?
    @categories = Shopify::ProductCatalog::SUPPORTED_CATEGORIES
    @selected_category = selected_category.to_s.presence

    set_facet_state(catalog: catalog, selected_category: @selected_category)

    @catalog_page = catalog.page(
      first: per_page,
      after: params[:after],
      before: params[:before],
      category: @selected_category,
      availability: @facet_availability,
      sizes: @facet_selected_sizes,
      price_min: @facet_price_min,
      price_max: @facet_price_max,
      sort_by: @facet_sort_by
    )

    set_storefront_notice(client)
  end

  def set_facet_state(catalog:, selected_category:, designer: nil)
    @facet_price_min = parse_amount(params[:price_min])
    @facet_price_max = parse_amount(params[:price_max])
    @facet_selected_sizes = Array(params[:sizes]).map(&:to_s).reject(&:blank?)
    @facet_availability = params[:availability].to_s.presence
    @facet_sort_by = params[:sort_by].to_s.presence || "featured"

    @facet_max_price = catalog.max_price(
      category: selected_category,
      designer: designer,
      availability: @facet_availability,
      sizes: @facet_selected_sizes,
      price_min: @facet_price_min,
      price_max: @facet_price_max
    )

    @facet_sizes = catalog.available_sizes(
      category: selected_category,
      designer: designer,
      availability: @facet_availability,
      price_min: @facet_price_min,
      price_max: @facet_price_max
    )
    @facet_sizes = SIZE_OPTIONS if @facet_sizes.blank?
  end

  def selected_category_from_params
    explicit = params[:category].to_s.presence
    return explicit if explicit.present?

    Array(params[:product_types]).map(&:to_s).find(&:present?)
  end

  def parse_amount(value)
    return nil if value.blank?

    Float(value)
  rescue ArgumentError, TypeError
    nil
  end

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
