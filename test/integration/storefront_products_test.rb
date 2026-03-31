require "test_helper"

class StorefrontProductsTest < ActionDispatch::IntegrationTest
  test "shows fallback product detail page" do
    get "/products/sample-001"

    assert_response :success
    assert_select "h1", "Abyss Selvedge 14oz"
    assert_select "p", /USD 168.00/
  end

  test "returns 404 when product does not exist" do
    get "/products/not-a-real-product"

    assert_response :not_found
  end
end
