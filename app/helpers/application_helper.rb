module ApplicationHelper
  def cart_nav_label
    "Cart (#{cart_item_count})"
  end

  def cart_count
    cart_item_count
  end

  def nav_link_class(section)
    classes = [ "site-nav-link" ]
    classes << "active" if nav_section == section
    classes.join(" ")
  end

  def utility_link_class(section = nil)
    classes = [ "site-nav-utility-link" ]
    classes << "active" if section.present? && nav_section == section
    classes.join(" ")
  end

  def product_designer_label(product)
    Shopify::ProductCatalog::SUPPORTED_DESIGNERS[product.designer] || product.designer.to_s.tr("-", " ").split.map(&:capitalize).join(" ")
  end

  def product_style_label(product)
    label = product.category.to_s.strip
    return "Raw Denim" if label.blank?

    label.capitalize
  end

  def product_card_price(product)
    amount = product.price_amount
    return format("$ %.2f", amount.to_f) if amount.present?

    product.price
  end

  def facet_query_params(extra = {})
    base = {
      "availability" => params[:availability].presence,
      "price_min" => params[:price_min].presence,
      "price_max" => params[:price_max].presence,
      "sort_by" => params[:sort_by].presence,
      "per" => params[:per].presence,
      "category" => params[:category].presence,
      "view" => params[:view].presence
    }

    sizes = Array(params[:sizes]).map(&:to_s).reject(&:blank?)
    product_types = Array(params[:product_types]).map(&:to_s).reject(&:blank?)

    base["sizes"] = sizes if sizes.present?
    base["product_types"] = product_types if product_types.present?

    base.merge(extra.stringify_keys).compact
  end

  private

  def nav_section
    path = request.path.to_s

    return :cart if path.start_with?("/cart")
    return :shop if path.start_with?("/shop") || path.start_with?("/categories") || path.start_with?("/products") || path.start_with?("/designers")

    :home
  end

  def cart_item_count
    items = session[:cart_items] || {}
    items.values.map(&:to_i).sum
  end
end
