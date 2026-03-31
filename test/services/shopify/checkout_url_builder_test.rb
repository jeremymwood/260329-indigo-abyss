require "test_helper"

module Shopify
  class CheckoutUrlBuilderTest < ActiveSupport::TestCase
    test "build returns checkout url when lines are valid" do
      builder = CheckoutUrlBuilder.new(store_domain: "indigo-abyss.myshopify.com")
      lines = [
        SessionCart::CheckoutLine.new(identifier: "a", quantity: 2, variant_id: "gid://shopify/ProductVariant/401001"),
        SessionCart::CheckoutLine.new(identifier: "b", quantity: 1, variant_id: "401002")
      ]

      result = builder.build(lines: lines)

      assert result.ok?
      assert_equal "https://indigo-abyss.myshopify.com/cart/401001:2,401002:1?checkout", result.url
    end

    test "build rejects invalid lines" do
      builder = CheckoutUrlBuilder.new(store_domain: "indigo-abyss.myshopify.com")
      lines = [SessionCart::CheckoutLine.new(identifier: "bad", quantity: 1, variant_id: nil)]

      result = builder.build(lines: lines)

      assert_not result.ok?
      assert_match(/invalid items/i, result.error)
    end
  end
end
