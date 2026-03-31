require "cgi"
require "base64"

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

    PRODUCTS_PAGE_FORWARD_QUERY = <<~GRAPHQL
      query ProductsPageForward($first: Int!, $after: String) {
        products(first: $first, after: $after, sortKey: BEST_SELLING) {
          edges {
            cursor
            node {
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
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
        }
      }
    GRAPHQL

    PRODUCTS_PAGE_BACKWARD_QUERY = <<~GRAPHQL
      query ProductsPageBackward($last: Int!, $before: String) {
        products(last: $last, before: $before, sortKey: BEST_SELLING) {
          edges {
            cursor
            node {
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
          pageInfo {
            hasNextPage
            hasPreviousPage
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
      return fallback_products.first(limit) if !@client.configured?

      data = @client.query(query: FEATURED_PRODUCTS_QUERY, variables: { first: limit })
      nodes = data&.dig("products", "nodes")
      return fallback_products.first(limit) if nodes.blank?

      nodes.map { |node| to_product_card(node, truncate_description: true) }
    end

    def page(first:, after: nil, before: nil)
      return fallback_page(first: first, after: after, before: before) if !@client.configured?

      live_page(first: first, after: after, before: before) || fallback_page(first: first, after: after, before: before)
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

    def live_page(first:, after:, before:)
      if before.present?
        data = @client.query(query: PRODUCTS_PAGE_BACKWARD_QUERY, variables: { last: first, before: before })
      else
        data = @client.query(query: PRODUCTS_PAGE_FORWARD_QUERY, variables: { first: first, after: after })
      end

      products_data = data&.dig("products")
      return nil if products_data.blank?

      edges = products_data["edges"] || []
      product_cards = edges.map { |edge| to_product_card(edge["node"], truncate_description: true) }
      page_info = products_data["pageInfo"] || {}

      ProductPage.new(
        products: product_cards,
        next_cursor: page_info["hasNextPage"] ? edges.last&.dig("cursor") : nil,
        prev_cursor: page_info["hasPreviousPage"] ? edges.first&.dig("cursor") : nil
      )
    end

    def fallback_page(first:, after:, before:)
      rows = fallback_rows
      return ProductPage.new(products: [], next_cursor: nil, prev_cursor: nil) if rows.blank?

      per_page = [[first.to_i, 1].max, 24].min

      if before.present?
        end_index = decode_fallback_cursor(before) || rows.length
        end_index = [[end_index, 0].max, rows.length].min
        start_index = [end_index - per_page, 0].max
      else
        start_index = after.present? ? (decode_fallback_cursor(after).to_i + 1) : 0
        start_index = [[start_index, 0].max, rows.length].min
        end_index = [start_index + per_page, rows.length].min
      end

      window = rows[start_index...end_index] || []
      cards = window.map { |row| fallback_row_to_card(row, truncate_description: true) }

      has_previous = start_index.positive?
      has_next = end_index < rows.length

      ProductPage.new(
        products: cards,
        next_cursor: has_next ? encode_fallback_cursor(end_index - 1) : nil,
        prev_cursor: has_previous ? encode_fallback_cursor(start_index) : nil
      )
    end

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
      price_node = node.dig("priceRange", "minVariantPrice") || {}
      amount = price_node["amount"]&.to_f
      currency = price_node["currencyCode"]

      ProductCard.new(
        id: node["id"],
        handle: node["handle"],
        title: node["title"],
        description: truncate_description ? truncate(node["description"]) : detail_copy(node["description"]),
        image_url: node.dig("featuredImage", "url") || fallback_image,
        price: money_label(amount: amount, currency: currency),
        price_amount: amount,
        currency_code: currency
      )
    end

    def fallback_product(identifier)
      decoded_identifier = CGI.unescape(identifier.to_s)
      row = fallback_rows.find { |item| item[:id] == decoded_identifier || item[:handle] == decoded_identifier }
      return nil if row.blank?

      fallback_row_to_card(row, truncate_description: false)
    end

    def fallback_products
      fallback_rows.map { |row| fallback_row_to_card(row, truncate_description: true) }
    end

    def fallback_row_to_card(row, truncate_description:)
      ProductCard.new(
        id: row[:id],
        handle: row[:handle],
        title: row[:title],
        description: truncate_description ? truncate(row[:description]) : detail_copy(row[:description]),
        image_url: row[:image_url],
        price: row[:price],
        price_amount: row[:price_amount],
        currency_code: row[:currency_code]
      )
    end

    def encode_fallback_cursor(index)
      Base64.urlsafe_encode64("idx:#{index}")
    end

    def decode_fallback_cursor(cursor)
      decoded = Base64.urlsafe_decode64(cursor.to_s)
      return nil if !decoded.start_with?("idx:")

      Integer(decoded.delete_prefix("idx:"), exception: false)
    rescue ArgumentError
      nil
    end

    def fallback_rows
      [
        {
          id: "sample-001",
          handle: "abyss-selvedge-14oz",
          title: "Abyss Selvedge 14oz",
          description: "Straight fit, loom-state selvedge woven for high-contrast fades and long break-in life.",
          image_url: "https://images.unsplash.com/photo-1582552938357-32b906df40cb?auto=format&fit=crop&w=1200&q=80",
          price: "USD 168.00",
          price_amount: 168.00,
          currency_code: "USD"
        },
        {
          id: "sample-002",
          handle: "nocturne-taper-13oz",
          title: "Nocturne Taper 13oz",
          description: "Roomy top block with an aggressive taper and deep indigo cast for clean vertical fade lines.",
          image_url: "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=1200&q=80",
          price: "USD 154.00",
          price_amount: 154.00,
          currency_code: "USD"
        },
        {
          id: "sample-003",
          handle: "rinse-black-warp-12oz",
          title: "Rinse Black Warp 12oz",
          description: "Sulfur-black warp with indigo core yarn for tone-rich wear patterns and subtle electric highs.",
          image_url: "https://images.unsplash.com/photo-1552902865-b72c031ac5ea?auto=format&fit=crop&w=1200&q=80",
          price: "USD 182.00",
          price_amount: 182.00,
          currency_code: "USD"
        }
      ]
    end

    def money_label(amount:, currency:)
      return "Price unavailable" if amount.blank? || currency.blank?

      "#{currency} #{format('%.2f', amount)}"
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
