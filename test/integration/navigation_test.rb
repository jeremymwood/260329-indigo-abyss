require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "renders retail-style header menu on root" do
    get "/"

    assert_response :success
    assert_select "nav.site-nav"
    assert_select "a.site-brand", "Indigo Abyss"
    assert_select "a.site-nav-link", text: "New Arrivals"
    assert_select "summary", "Designers"
    assert_select "summary", "Categories"
    assert_select "a.site-nav-link", text: "Gift Card"
    assert_select "a.site-nav-link", text: "Sale"
    assert_select "a.site-nav-utility-link", text: "Cart (0)"
  end

  test "shop page marks new arrivals link active" do
    get "/shop"

    assert_response :success
    assert_select "a.site-nav-link.active", text: "New Arrivals"
  end

  test "product detail page keeps shop navigation active" do
    get "/products/sample-001"

    assert_response :success
    assert_select "a.site-nav-link.active", text: "New Arrivals"
  end

  test "cart page marks utility cart link active" do
    get "/cart"

    assert_response :success
    assert_select "a.site-nav-utility-link.active", text: "Cart (0)"
  end

  test "cart utility count updates after adding item" do
    post "/cart/items", params: { product_id: "abyss-selvedge-14oz", quantity: 2 }
    follow_redirect!

    assert_response :success
    assert_select "a.site-nav-utility-link", text: "Cart (2)"
  end
end
