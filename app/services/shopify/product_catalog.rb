require "cgi"

module Shopify
  class ProductCatalog
    FEATURED_PRODUCTS_QUERY = <<~GRAPHQL
      query DenimShowcase($first: Int!) {
        products(first: $first, sortKey: BEST_SELLING) {
          nodes {
            id
            handle
            title
            description
            featuredImage {
              url
              altText
            }
            priceRange {
              minVariantPrice {
                amount
                currencyCode
              }
            }
          }
        }
      }
    GRAPHQL

    PRODUCT_BY_HANDLE_QUERY = <<~GRAPHQL
      query ProductByHandle($handle: String!) {
        product(handle: $handle) {
          id
          handle
          title
          description
          featuredImage {
            url
            altText
          }
          priceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
        }
      }
    GRAPHQL

    PRODUCT_BY_ID_QUERY = <<~GRAPHQL
      query ProductById($id: ID!) {
        node(id: $id) {
          ... on Product {
            id
            handle
            title
            description
            featuredImage {
              url
              altText
            }
            priceRange {
              minVariantPrice {
                amount
                currencyCode
              }
            }
          }
        }
      }
    GRAPHQL

    def initialize(client: StorefrontClient.new)
      @client = client
    end

    def featured(limit: 6)
      return fallback_products if !@client.configured?

      data = @client.query(query: FEATURED_PRODUCTS_QUERY, variables: { first: limit })
      nodes = data&.dig("products", "nodes")
      return fallback_products if nodes.blank?

      nodes.map { |node| to_product_card(node, truncate_description: true) }
    end

    def find(identifier)
      return nil if identifier.blank?

      if @client.configured?
        node = live_product(identifier)
        return to_product_card(node, truncate_description: false) if node.present?
      end

      fallback_product(identifier)
    end

    private

    def live_product(identifier)
      decoded_identifier = CGI.unescape(identifier.to_s)

      if decoded_identifier.start_with?("gid://")
        data = @client.query(query: PRODUCT_BY_ID_QUERY, variables: { id: decoded_identifier })
        return data&.dig("node")
      end

      data = @client.query(query: PRODUCT_BY_HANDLE_QUERY, variables: { handle: decoded_identifier })
      data&.dig("product")
    end

    def to_product_card(node, truncate_description:)
      ProductCard.new(
        id: node["id"],
        handle: node["handle"],
        title: node["title"],
        description: truncate_description ? truncate(node["description"]) : detail_copy(node["description"]),
        image_url: node.dig("featuredImage", "url") || fallback_image,
        price: money_label(node.dig("priceRange", "minVariantPrice"))
      )
    end

    def fallback_product(identifier)
      decoded_identifier = CGI.unescape(identifier.to_s)
      row = fallback_rows.find { |item| item[:id] == decoded_identifier || item[:handle] == decoded_identifier }
      return nil if row.blank?

      ProductCard.new(**row)
    end

    def fallback_products
      fallback_rows.map do |row|
        ProductCard.new(
          id: row[:id],
          handle: row[:handle],
          title: row[:title],
          description: truncate(row[:description]),
          image_url: row[:image_url],
          price: row[:price]
        )
      end
    end

    def fallback_rows
      [
        {
          id: "sample-001",
          handle: "abyss-selvedge-14oz",
          title: "Abyss Selvedge 14oz",
          description: "Straight fit, loom-state selvedge woven for high-contrast fades and long break-in life.",
          image_url: "https://images.unsplash.com/photo-1582552938357-32b906df40cb?auto=format&fit=crop&w=1200&q=80",
          price: "USD 168.00"
        },
        {
          id: "sample-002",
          handle: "nocturne-taper-13oz",
          title: "Nocturne Taper 13oz",
          description: "Roomy top block with an aggressive taper and deep indigo cast for clean vertical fade lines.",
          image_url: "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=1200&q=80",
          price: "USD 154.00"
        },
        {
          id: "sample-003",
          handle: "rinse-black-warp-12oz",
          title: "Rinse Black Warp 12oz",
          description: "Sulfur-black warp with indigo core yarn for tone-rich wear patterns and subtle electric highs.",
          image_url: "https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=1200&q=80",
          price: "USD 182.00"
        }
      ]
    end

    def money_label(price_node)
      return "Price unavailable" if price_node.blank?

      amount = format("%.2f", price_node["amount"].to_f)
      "#{price_node["currencyCode"]} #{amount}"
    end

    def truncate(text, max = 100)
      return "Raw denim engineered for long wear and clean fades." if text.blank?
      return text if text.length <= max

      "#{text[0...max].rstrip}..."
    end

    def detail_copy(text)
      return "Raw denim engineered for long wear and clean fades." if text.blank?

      text
    end

    def fallback_image
      "https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=1200&q=80"
    end
  end
end
