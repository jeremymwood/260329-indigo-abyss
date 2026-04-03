require "test_helper"

class StorefrontDesignerTest < ActionDispatch::IntegrationTest
  test "renders designer collection page" do
    get "/designers/oni-denim"

    assert_response :success
    assert_select "h1", "Oni Denim"
    assert_select "nav.collection-breadcrumb"
    assert_select "aside.collection-sidebar"
    assert_select "section.product-grid .product-card", minimum: 1
  end

  test "supports category filter inside designer collection" do
    get "/designers/studio-dartisan", params: { category: "jackets", per: 24 }

    assert_response :success
    assert_select "a.pagination-link.active", "Jackets"
    assert_select ".product-category", minimum: 1
    assert_select ".product-category", /Jackets/
  end

  test "shows empty state for unknown designer" do
    get "/designers/not-real-designer"

    assert_response :success
    assert_select "h2", "No products available yet"
  end
end
