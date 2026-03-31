require "net/http"
require "json"

module Shopify
  class StorefrontClient
    ENDPOINT_PATH = "/api/2025-10/graphql.json".freeze
    REQUEST_TIMEOUT_SECONDS = 6

    attr_reader :last_error

    def initialize(store_domain: ENV["SHOPIFY_STORE_DOMAIN"], token: ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"])
      @store_domain = store_domain
      @token = token
      @last_error = nil
    end

    def configured?
      @store_domain.present? && @token.present?
    end

    def query(query:, variables: {})
      @last_error = nil
      return nil if !configured?

      uri = URI::HTTPS.build(host: @store_domain, path: ENDPOINT_PATH)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["X-Shopify-Storefront-Access-Token"] = @token
      req.body = { query: query, variables: variables }.to_json

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: REQUEST_TIMEOUT_SECONDS,
        read_timeout: REQUEST_TIMEOUT_SECONDS
      ) { |http| http.request(req) }

      payload = parse_json(response.body)

      if !response.is_a?(Net::HTTPSuccess)
        register_error(
          type: :http_error,
          message: "Storefront API returned HTTP #{response.code}",
          status: response.code.to_i
        )
        return nil
      end

      if payload.blank?
        register_error(type: :invalid_json, message: "Storefront API returned an invalid JSON payload")
        return nil
      end

      if payload["errors"].present?
        register_error(
          type: :graphql_error,
          message: "Storefront API returned GraphQL errors",
          graphql_error_count: payload["errors"].size
        )
        return nil
      end

      payload["data"]
    rescue Net::OpenTimeout, Net::ReadTimeout
      register_error(type: :timeout, message: "Storefront API request timed out")
      nil
    rescue StandardError => e
      register_error(type: :network_error, message: "Storefront API request failed", error_class: e.class.name)
      nil
    end

    private

    def parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def register_error(type:, message:, **context)
      @last_error = { type: type, message: message }.merge(context)

      Rails.logger.warn(
        {
          event: "shopify_storefront_error",
          type: type,
          message: message,
          store_domain: @store_domain
        }.merge(context.compact).to_json
      )
    end
  end
end
