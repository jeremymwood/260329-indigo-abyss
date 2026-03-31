require "test_helper"
require "base64"
require "nokogiri"

class StorefrontShopTest < ActionDispatch::IntegrationTest
  test "renders shop page with next link when more products exist" do
    get "/shop", params: { per: 2 }

    assert_response :success
    assert_select "h1", "Shop Raw Denim"
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
end
