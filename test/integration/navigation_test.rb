require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "renders nav with home active on root" do
    get "/"

    assert_response :success
    assert_select "nav.site-nav"
    assert_select "a.site-nav-link", text: "Home"
    assert_select "a.site-nav-link", text: "Shop"
    assert_select "a.site-nav-link", text: "Cart"
    assert_select "a.site-nav-link.active", text: "Home"
  end

  test "renders nav with shop active on shop page" do
    get "/shop"

    assert_response :success
    assert_select "a.site-nav-link.active", text: "Shop"
  end

  test "renders nav with shop active on product detail page" do
    get "/products/sample-001"

    assert_response :success
    assert_select "a.site-nav-link.active", text: "Shop"
  end

  test "renders nav with cart active on cart page" do
    get "/cart"

    assert_response :success
    assert_select "a.site-nav-link.active", text: "Cart"
  end
end
