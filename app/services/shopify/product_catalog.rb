require "cgi"
require "base64"
require "yaml"

module Shopify
  class ProductCatalog
    FALLBACK_PRODUCTS_PATH = Rails.root.join("config/fallback_products.yml").freeze
    SUPPORTED_CATEGORIES = %w[pants shirts jackets accessories].freeze
    SUPPORTED_DESIGNERS = {
      "oni-denim" => "Oni Denim",
      "iron-heart" => "Iron Heart",
      "samurai-jeans" => "Samurai Jeans",
      "studio-dartisan" => "Studio D'Artisan"
    }.freeze

    FEATURED_PRODUCTS_QUERY = <<~GRAPHQL
      query DenimShowcase($first: Int!) {
        products(first: $first, sortKey: BEST_SELLING) {
          nodes {
            id
            handle
            title
            description
            productType
            vendor
            featuredImage {
              url
              altText
            }
            images(first: 2) {
              nodes {
                url
                altText
              }
            }
            priceRange {
              minVariantPrice {
                amount
                currencyCode
              }
            }
            variants(first: 1) {
              nodes {
                id
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
              productType
              vendor
              featuredImage {
                url
                altText
              }
              images(first: 2) {
                nodes {
                  url
                  altText
                }
              }
              priceRange {
                minVariantPrice {
                  amount
                  currencyCode
                }
              }
              variants(first: 1) {
                nodes {
                  id
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
              productType
              vendor
              featuredImage {
                url
                altText
              }
              images(first: 2) {
                nodes {
                  url
                  altText
                }
              }
              priceRange {
                minVariantPrice {
                  amount
                  currencyCode
                }
              }
              variants(first: 1) {
                nodes {
                  id
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
          productType
          vendor
          featuredImage {
              url
              altText
            }
            images(first: 2) {
              nodes {
                url
                altText
              }
            }
            priceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
          variants(first: 1) {
            nodes {
              id
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
            productType
            vendor
            featuredImage {
              url
              altText
            }
            images(first: 2) {
              nodes {
                url
                altText
              }
            }
            priceRange {
              minVariantPrice {
                amount
                currencyCode
              }
            }
            variants(first: 1) {
              nodes {
                id
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

    def page(first:, after: nil, before: nil, category: nil, designer: nil, availability: nil, sizes: [], price_min: nil, price_max: nil, sort_by: "featured")
      return fallback_page(first: first, after: after, before: before, category: category, designer: designer, availability: availability, sizes: sizes, price_min: price_min, price_max: price_max, sort_by: sort_by) if !@client.configured?

      live_page(first: first, after: after, before: before, category: category, designer: designer, availability: availability, sizes: sizes, price_min: price_min, price_max: price_max, sort_by: sort_by) ||
        fallback_page(first: first, after: after, before: before, category: category, designer: designer, availability: availability, sizes: sizes, price_min: price_min, price_max: price_max, sort_by: sort_by)
    end

    def max_price(category: nil, designer: nil, availability: nil, sizes: [], price_min: nil, price_max: nil)
      rows = filtered_rows(category: category, designer: designer, availability: availability, sizes: sizes, price_min: price_min, price_max: price_max, sort_by: "featured")
      amounts = rows.map { |row| row[:price_amount].to_f }.select { |amount| amount.positive? }
      amounts.max || 0
    end

    def available_sizes(category: nil, designer: nil, availability: nil, price_min: nil, price_max: nil)
      rows = filtered_rows(category: category, designer: designer, availability: availability, sizes: [], price_min: price_min, price_max: price_max, sort_by: "featured")
      rows.map { |row| row[:size].to_s.strip }.reject(&:blank?).uniq.sort_by { |value| value.to_i }
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

    def live_page(first:, after:, before:, category:, designer:, availability:, sizes:, price_min:, price_max:, sort_by:)
      if before.present?
        data = @client.query(query: PRODUCTS_PAGE_BACKWARD_QUERY, variables: { last: first, before: before })
      else
        data = @client.query(query: PRODUCTS_PAGE_FORWARD_QUERY, variables: { first: first, after: after })
      end

      products_data = data&.dig("products")
      return nil if products_data.blank?

      edges = products_data["edges"] || []
      product_cards = edges.map { |edge| to_product_card(edge["node"], truncate_description: true) }
      product_cards = filter_products_by_designer(product_cards, designer)
      product_cards = filter_products_by_category(product_cards, category)

      price_min_amount = parse_amount(price_min)
      price_max_amount = parse_amount(price_max)
      product_cards = product_cards.select { |product| product.price_amount.to_f >= price_min_amount } if price_min_amount
      product_cards = product_cards.select { |product| product.price_amount.to_f <= price_max_amount } if price_max_amount

      product_cards = sort_products(product_cards, sort_by)
      page_info = products_data["pageInfo"] || {}

      ProductPage.new(
        products: product_cards,
        next_cursor: page_info["hasNextPage"] ? edges.last&.dig("cursor") : nil,
        prev_cursor: page_info["hasPreviousPage"] ? edges.first&.dig("cursor") : nil
      )
    end

    def fallback_page(first:, after:, before:, category:, designer:, availability:, sizes:, price_min:, price_max:, sort_by:)
      rows = filtered_rows(category: category, designer: designer, availability: availability, sizes: sizes, price_min: price_min, price_max: price_max, sort_by: sort_by)
      return ProductPage.new(products: [], next_cursor: nil, prev_cursor: nil) if rows.blank?

      per_page = [ [ first.to_i, 1 ].max, 24 ].min

      if before.present?
        end_index = decode_fallback_cursor(before) || rows.length
        end_index = [ [ end_index, 0 ].max, rows.length ].min
        start_index = [ end_index - per_page, 0 ].max
      else
        start_index = after.present? ? (decode_fallback_cursor(after).to_i + 1) : 0
        start_index = [ [ start_index, 0 ].max, rows.length ].min
        end_index = [ start_index + per_page, rows.length ].min
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
        image_url: primary_image_url(node),
        secondary_image_url: secondary_image_url(node),
        price: money_label(amount: amount, currency: currency),
        price_amount: amount,
        currency_code: currency,
        variant_id: node.dig("variants", "nodes", 0, "id"),
        category: normalize_category(node["productType"]),
        designer: normalize_designer(node["vendor"]),
        in_stock: true
      )
    end

    def primary_image_url(node)
      node.dig("featuredImage", "url") || node.dig("images", "nodes", 0, "url") || fallback_image
    end

    def secondary_image_url(node)
      node.dig("images", "nodes", 1, "url") || node.dig("images", "nodes", 0, "url") || primary_image_url(node)
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
        secondary_image_url: row[:secondary_image_url] || row[:image_url],
        price: row[:price],
        price_amount: row[:price_amount],
        currency_code: row[:currency_code],
        variant_id: row[:variant_id],
        category: normalize_category(row[:category]),
        designer: normalize_designer(row[:designer]),
        size: row[:size],
        in_stock: row[:in_stock],
        sales_rank: row[:sales_rank],
        created_at: row[:created_at]
      )
    end

    def filtered_rows(category:, designer:, availability:, sizes:, price_min:, price_max:, sort_by:)
      rows = fallback_rows

      designer_value = designer_filter(designer)
      rows = rows.select { |row| normalize_designer(row[:designer]) == designer_value } if designer_value.present?

      category_filter_value = category_filter(category)
      return [] if category_filter_value == :invalid
      rows = rows.select { |row| normalize_category(row[:category]) == category_filter_value } if category_filter_value.present?

      case availability.to_s
      when "in-stock"
        rows = rows.select { |row| row[:in_stock] == true }
      when "out-of-stock"
        rows = rows.select { |row| row[:in_stock] == false }
      end

      normalized_sizes = Array(sizes).map(&:to_s).reject(&:blank?)
      rows = rows.select { |row| normalized_sizes.include?(row[:size].to_s) } if normalized_sizes.present?

      price_min_amount = parse_amount(price_min)
      rows = rows.select { |row| row[:price_amount].to_f >= price_min_amount } if price_min_amount

      price_max_amount = parse_amount(price_max)
      rows = rows.select { |row| row[:price_amount].to_f <= price_max_amount } if price_max_amount

      sort_rows(rows, sort_by)
    end

    def filter_products_by_category(products, category)
      normalized = category_filter(category)
      return products if normalized.nil?
      return [] if normalized == :invalid

      products.select { |product| product.category == normalized }
    end

    def filter_products_by_designer(products, designer)
      normalized = designer_filter(designer)
      return products if normalized.blank?

      products.select { |product| product.designer == normalized }
    end

    def sort_rows(rows, sort_by)
      mode = canonical_sort(sort_by)

      case mode
      when "alpha-asc"
        rows.sort_by { |row| row[:title].to_s.downcase }
      when "alpha-desc"
        rows.sort_by { |row| row[:title].to_s.downcase }.reverse
      when "price-asc"
        rows.sort_by { |row| row[:price_amount].to_f }
      when "price-desc"
        rows.sort_by { |row| row[:price_amount].to_f }.reverse
      when "date-asc"
        rows.sort_by { |row| row[:created_at] || Time.at(0) }
      when "date-desc"
        rows.sort_by { |row| row[:created_at] || Time.at(0) }.reverse
      when "best-selling"
        rows.sort_by { |row| row[:sales_rank].to_i.zero? ? 9_999 : row[:sales_rank].to_i }
      else
        rows
      end
    end

    def sort_products(products, sort_by)
      mode = canonical_sort(sort_by)

      case mode
      when "alpha-asc"
        products.sort_by { |product| product.title.to_s.downcase }
      when "alpha-desc"
        products.sort_by { |product| product.title.to_s.downcase }.reverse
      when "price-asc"
        products.sort_by { |product| product.price_amount.to_f }
      when "price-desc"
        products.sort_by { |product| product.price_amount.to_f }.reverse
      else
        products
      end
    end

    def canonical_sort(value)
      raw = value.to_s
      return "featured" if raw.blank?

      raw
    end

    def parse_amount(value)
      return nil if value.blank?

      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    def category_filter(value)
      raw = value.to_s.strip.downcase
      return nil if raw.blank?

      SUPPORTED_CATEGORIES.include?(raw) ? raw : :invalid
    end

    def designer_filter(value)
      normalized = normalize_designer(value)
      return nil if normalized.blank?

      normalized
    end

    def normalize_designer(value)
      raw = value.to_s.strip.downcase
      return nil if raw.blank?

      raw.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|\-\z/, "")
    end

    def normalize_category(value)
      normalized = value.to_s.strip.downcase
      return nil if normalized.blank?

      SUPPORTED_CATEGORIES.include?(normalized) ? normalized : nil
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
      @fallback_rows ||= begin
        rows = YAML.safe_load_file(FALLBACK_PRODUCTS_PATH, permitted_classes: [], aliases: false)
        Array(rows).map { |row| normalize_fallback_row(row) }
      rescue StandardError
        []
      end
    end

    def normalize_fallback_row(row)
      normalized = row.to_h.transform_keys(&:to_sym)
      normalized[:price_amount] = normalized[:price_amount].to_f if normalized[:price_amount].present?
      normalized[:size] = normalized[:size].to_s if normalized[:size].present?
      normalized[:in_stock] = normalize_in_stock(normalized[:in_stock])
      normalized[:sales_rank] = normalized[:sales_rank].to_i if normalized[:sales_rank].present?
      normalized[:created_at] = parse_timestamp(normalized[:created_at])
      normalized
    end

    def normalize_in_stock(value)
      return value if value == true || value == false

      !value.to_s.strip.casecmp("false").zero?
    end

    def parse_timestamp(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def money_label(amount:, currency:)
      return "Price unavailable" if amount.blank? || currency.blank?

      "#{currency} #{format('%.2f', amount)}"
    end

    def truncate(text, max = 52)
      return "Straight fit." if text.blank?

      first_line = text.to_s.split(/[\r\n]/).first.to_s.strip
      first_clause = first_line.split(".").first.to_s.strip
      candidate = first_clause.presence || first_line
      return candidate if candidate.length <= max

      "#{candidate[0...max].rstrip}..."
    end

    def detail_copy(text)
      return "Straight fit." if text.blank?

      text
    end

    def fallback_image
      "https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=1200&q=80"
    end
  end
end
