require "test_helper"

module Shopify
  class ProductCatalogTest < ActiveSupport::TestCase
    class OfflineClient
      def configured?
        false
      end
    end

    test "featured reads fallback products from config fixture" do
      catalog = ProductCatalog.new(client: OfflineClient.new)

      products = catalog.featured(limit: 2)

      assert_equal 2, products.length
      assert_equal "Abyss Selvedge 14oz", products.first.title
      assert_equal "gid://shopify/ProductVariant/401001", products.first.variant_id
      assert_equal "USD 168.00", products.first.price
    end

    test "find returns fallback product by handle" do
      catalog = ProductCatalog.new(client: OfflineClient.new)

      product = catalog.find("nocturne-taper-13oz")

      assert_not_nil product
      assert_equal "Nocturne Taper 13oz", product.title
      assert_equal "gid://shopify/ProductVariant/401002", product.variant_id
    end
  end
end
