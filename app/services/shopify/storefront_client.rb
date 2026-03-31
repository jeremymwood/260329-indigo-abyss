require "net/http"
require "json"

module Shopify
  class StorefrontClient
    ENDPOINT_PATH = "/api/2025-10/graphql.json".freeze

    def initialize(store_domain: ENV["SHOPIFY_STORE_DOMAIN"], token: ENV["SHOPIFY_STOREFRONT_ACCESS_TOKEN"])
      @store_domain = store_domain
      @token = token
    end

    def configured?
      @store_domain.present? && @token.present?
    end

    def query(query:, variables: {})
      return if !configured?

      uri = URI::HTTPS.build(host: @store_domain, path: ENDPOINT_PATH)
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["X-Shopify-Storefront-Access-Token"] = @token
      req.body = { query: query, variables: variables }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      payload = JSON.parse(response.body)

      return nil if !response.is_a?(Net::HTTPSuccess) || payload["errors"].present?

      payload["data"]
    rescue StandardError
      nil
    end
  end
end
