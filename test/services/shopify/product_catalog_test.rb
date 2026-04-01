require "test_helper"

module Shopify
  class ProductCatalogTest < ActiveSupport::TestCase
    class OfflineClient
      def configured?
        false
      end
    end

    class OnlineClient
      def initialize(payload:)
        @payload = payload
      end

      def configured?
        true
      end

      def query(query:, variables: {})
        @payload
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

    test "featured uses live storefront data when available" do
      payload = {
        "products" => {
          "nodes" => [
            {
              "id" => "gid://shopify/Product/42",
              "handle" => "edge-selvedge",
              "title" => "Edge Selvedge",
              "description" => "Live storefront denim card",
              "productType" => "pants",
              "featuredImage" => { "url" => "https://cdn.example.com/edge.jpg" },
              "priceRange" => {
                "minVariantPrice" => {
                  "amount" => "199.0",
                  "currencyCode" => "USD"
                }
              },
              "variants" => {
                "nodes" => [ { "id" => "gid://shopify/ProductVariant/9001" } ]
              }
            }
          ]
        }
      }

      catalog = ProductCatalog.new(client: OnlineClient.new(payload: payload))
      product = catalog.featured(limit: 1).first

      assert_equal "Edge Selvedge", product.title
      assert_equal "USD 199.00", product.price
      assert_equal "gid://shopify/ProductVariant/9001", product.variant_id
      assert_equal "pants", product.category
    end

    test "featured falls back when live storefront data is missing" do
      catalog = ProductCatalog.new(client: OnlineClient.new(payload: nil))

      products = catalog.featured(limit: 1)

      assert_equal 1, products.length
      assert_equal "Abyss Selvedge 14oz", products.first.title
    end

    test "fallback fixture now includes 20 categorized products" do
      catalog = ProductCatalog.new(client: OfflineClient.new)

      products = catalog.featured(limit: 24)

      assert_equal 20, products.length
      assert_equal "pants", products.first.category
      assert_equal "accessories", products.last.category
    end

    test "fallback pagination supports multiple pages with 20 items" do
      catalog = ProductCatalog.new(client: OfflineClient.new)

      first_page = catalog.page(first: 12)
      second_page = catalog.page(first: 12, after: first_page.next_cursor)

      assert_equal 12, first_page.products.length
      assert_not_nil first_page.next_cursor
      assert_equal 8, second_page.products.length
      assert_not_nil second_page.prev_cursor
      assert_nil second_page.next_cursor
      assert_equal "Harbor Slim Straight 12oz", second_page.products.first.title
    end

    test "fallback page filters by supported category" do
      catalog = ProductCatalog.new(client: OfflineClient.new)

      page = catalog.page(first: 24, category: "jackets")

      assert page.products.any?
      assert page.products.all? { |product| product.category == "jackets" }
    end
  end
end
