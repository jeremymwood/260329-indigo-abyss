module ApplicationHelper
  def nav_link_class(section)
    classes = [ "site-nav-link" ]
    classes << "active" if nav_section == section
    classes.join(" ")
  end

  private

  def nav_section
    path = request.path.to_s

    return :cart if path.start_with?("/cart")
    return :shop if path.start_with?("/shop") || path.start_with?("/products")

    :home
  end
end
