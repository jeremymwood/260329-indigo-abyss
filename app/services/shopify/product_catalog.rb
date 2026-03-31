module Shopify
  class ProductCatalog
    PRODUCT_QUERY = <<~GRAPHQL
      query DenimShowcase($first: Int!) {
        products(first: $first, sortKey: BEST_SELLING) {
          nodes {
            id
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

      data = @client.query(query: PRODUCT_QUERY, variables: { first: limit })
      nodes = data&.dig("products", "nodes")
      return fallback_products if nodes.blank?

      nodes.map { |node| to_product_card(node) }
    end

    private

    def to_product_card(node)
      ProductCard.new(
        id: node["id"],
        title: node["title"],
        description: truncate(node["description"]),
        image_url: node.dig("featuredImage", "url") || fallback_image,
        price: money_label(node.dig("priceRange", "minVariantPrice"))
      )
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

    def fallback_image
      "https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=1200&q=80"
    end

    def fallback_products
      [
        ProductCard.new(
          id: "sample-001",
          title: "Abyss Selvedge 14oz",
          description: "Straight fit, loom-state selvedge woven for high-contrast fades.",
          image_url: "https://images.unsplash.com/photo-1582552938357-32b906df40cb?auto=format&fit=crop&w=1200&q=80",
          price: "USD 168.00"
        ),
        ProductCard.new(
          id: "sample-002",
          title: "Nocturne Taper 13oz",
          description: "Roomy top block with an aggressive taper and deep indigo cast.",
          image_url: "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=1200&q=80",
          price: "USD 154.00"
        ),
        ProductCard.new(
          id: "sample-003",
          title: "Rinse Black Warp 12oz",
          description: "Sulfur-black warp with indigo core yarn for tone-rich wear patterns.",
          image_url: "https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=1200&q=80",
          price: "USD 182.00"
        )
      ]
    end
  end
end
