require "test_helper"

class CartFlowTest < ActionDispatch::IntegrationTest
  setup do
    @original_store_domain = ENV["SHOPIFY_STORE_DOMAIN"]
  end

  teardown do
    ENV["SHOPIFY_STORE_DOMAIN"] = @original_store_domain
  end

  test "add update and remove cart item" do
    post "/cart/items", params: { product_id: "abyss-selvedge-14oz", quantity: 2 }
    assert_redirected_to cart_path

    follow_redirect!
    assert_response :success
    assert_select "h2", "Abyss Selvedge 14oz"
    assert_select ".cart-item-subtotal", /USD 336.00/

    patch "/cart/items/abyss-selvedge-14oz", params: { quantity: 3 }
    assert_redirected_to cart_path

    follow_redirect!
    assert_select ".cart-item-subtotal", /USD 504.00/
    assert_select ".cart-summary strong", /USD 504.00/

    delete "/cart/items/abyss-selvedge-14oz"
    assert_redirected_to cart_path

    follow_redirect!
    assert_select "h2", "Your cart is empty"
  end

  test "checkout redirects to shopify cart permalink" do
    ENV["SHOPIFY_STORE_DOMAIN"] = "indigo-abyss.myshopify.com"

    post "/cart/items", params: { product_id: "abyss-selvedge-14oz", quantity: 2 }
    post "/cart/checkout"

    assert_redirected_to "https://indigo-abyss.myshopify.com/cart/401001:2?checkout"
  end

  test "checkout fails with invalid cart line" do
    ENV["SHOPIFY_STORE_DOMAIN"] = "indigo-abyss.myshopify.com"

    post "/cart/items", params: { product_id: "unknown-denim", quantity: 1 }
    post "/cart/checkout"

    assert_redirected_to cart_path
    follow_redirect!
    assert_select ".alert", /Cart contains invalid items/
  end
end
