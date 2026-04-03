module ApplicationHelper
  def cart_nav_label
    "Cart (#{cart_item_count})"
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

  private

  def nav_section
    path = request.path.to_s

    return :cart if path.start_with?("/cart")
    return :shop if path.start_with?("/shop") || path.start_with?("/products")

    :home
  end

  def cart_item_count
    items = session[:cart_items] || {}
    items.values.map(&:to_i).sum
  end
end
