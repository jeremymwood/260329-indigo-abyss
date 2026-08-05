require "test_helper"
require "nokogiri"

class StorefrontDesignerTest < ActionDispatch::IntegrationTest
  test "renders designer collection page" do
    get "/designers/oni-denim"

    assert_response :success
    assert_select "h1", "Oni Denim"
    assert_select "aside.collection-sidebar", false
    assert_select "#FacetFiltersForm"
    assert_select "section.product-grid .product-card", minimum: 1
  end

  test "supports category filter inside designer collection" do
    get "/designers/studio-dartisan", params: { category: "jackets", per: 24 }

    assert_response :success
    assert_select "#FacetFiltersForm"
    assert_select "input[type='checkbox'][name='product_types[]'][value='jackets'][checked='checked']"
    assert_select ".product-card", minimum: 0
    assert_select ".empty-state", minimum: 0
  end

  test "shows empty state for unknown designer" do
    get "/designers/not-real-designer"

    assert_response :success
    assert_select "h2", "No products available yet"
  end
end
