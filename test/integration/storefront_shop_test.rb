require "test_helper"
require "base64"
require "nokogiri"

class StorefrontShopTest < ActionDispatch::IntegrationTest
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

  test "renders shop page with next link when more products exist" do
    get "/shop", params: { per: 2 }

    assert_response :success
    assert_select "h1", "Shop"
    assert_select "a", "Next"
  end

  test "renders previous link on later page" do
    get "/shop", params: { per: 2 }

    next_href = Nokogiri::HTML(response.body).at_css("a[href*='after=']")&.[]("href")
    assert next_href.present?, "Expected a next link"

    get next_href

    assert_response :success
    assert_select "a", "Previous"
  end

  test "renders empty state when pagination cursor is beyond available data" do
    cursor = Base64.urlsafe_encode64("idx:999")

    get "/shop", params: { after: cursor, per: 2 }

    assert_response :success
    assert_select "h2", "No products available yet"
  end

  test "renders facet dropdown and supports category query" do
    get "/categories/jackets", params: { per: 24 }

    assert_response :success
    assert_select "h1", "Shop Jackets"
    assert_select "#FacetFiltersForm"
    assert_select "input[type='checkbox'][name='product_types[]'][value='jackets'][checked='checked']"
    assert_select ".product-category", minimum: 1
    assert_select ".product-category", /Jackets/
  end

  test "renders category-specific empty message when category has no products" do
    get "/categories/nonexistent", params: { per: 24 }

    assert_response :success
    assert_select "p", /No products found in/
  end

  test "shows fallback alert when live storefront query fails" do
    with_storefront_client(FakeClient.new) do
      get "/shop"
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
