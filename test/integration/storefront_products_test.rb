require "test_helper"

class StorefrontProductsTest < ActionDispatch::IntegrationTest
  class FakeClient
    attr_reader :last_error

    def configured?
      true
    end

    def query(query:, variables: {})
      @last_error = { type: :timeout, message: "timeout" }
      nil
    end
  end

  test "shows fallback product detail page" do
    get "/products/sample-001"

    assert_response :success
    assert_select "h1", "Abyss Selvedge 14oz"
    assert_select "p", /USD 168.00/
  end

  test "renders home page with featured products" do
    get "/"

    assert_response :success
    assert_select "h1", "Indigo Abyss"
    assert_select ".product-grid .product-card", minimum: 1
  end

  test "returns 404 when product does not exist" do
    get "/products/not-a-real-product"

    assert_response :not_found
  end

  test "shows fallback alert on home page when live query fails" do
    with_storefront_client(FakeClient.new) do
      get "/"
    end

    assert_response :success
    assert_select ".flash.alert", /showing showcase products/
  end

  private

  def with_storefront_client(fake_client)
    client_singleton = Shopify::StorefrontClient.singleton_class
    original_new = Shopify::StorefrontClient.method(:new)
    client_singleton.define_method(:new) { |*_args, **_kwargs| fake_client }
    yield
  ensure
    client_singleton.define_method(:new, original_new)
  end
end
