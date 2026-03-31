require "test_helper"

module Shopify
  class StorefrontClientTest < ActiveSupport::TestCase
    class CaptureLogger
      attr_reader :warnings

      def initialize
        @warnings = []
      end

      def warn(message)
        @warnings << message
      end
    end

    class FakeResponse
      attr_reader :code, :body

      def initialize(code:, body:, success:)
        @code = code
        @body = body
        @success = success
      end

      def is_a?(klass)
        return @success if klass == Net::HTTPSuccess

        super
      end
    end

    test "logs timeout errors without token leakage" do
      client = StorefrontClient.new(store_domain: "indigo-abyss.myshopify.com", token: "top-secret-token")
      logger = CaptureLogger.new

      with_logger(logger) do
        with_http_start(->(*_args) { raise Net::ReadTimeout }) do
          assert_nil client.query(query: "query { products(first: 1) { nodes { id } } }")
        end
      end

      assert_equal :timeout, client.last_error[:type]
      assert_includes logger.warnings.join("\n"), "shopify_storefront_error"
      refute_includes logger.warnings.join("\n"), "top-secret-token"
    end

    test "handles non-success http responses with status context" do
      client = StorefrontClient.new(store_domain: "indigo-abyss.myshopify.com", token: "token")
      logger = CaptureLogger.new
      response = FakeResponse.new(code: "502", body: "{}", success: false)

      with_logger(logger) do
        with_http_start(http_start_with(response)) do
          assert_nil client.query(query: "query { products(first: 1) { nodes { id } } }")
        end
      end

      assert_equal :http_error, client.last_error[:type]
      assert_equal 502, client.last_error[:status]
      assert_includes logger.warnings.join("\n"), "\"status\":502"
    end

    test "handles graphql errors with count context" do
      client = StorefrontClient.new(store_domain: "indigo-abyss.myshopify.com", token: "token")
      logger = CaptureLogger.new
      response = FakeResponse.new(
        code: "200",
        body: { errors: [ { message: "boom" } ] }.to_json,
        success: true
      )

      with_logger(logger) do
        with_http_start(http_start_with(response)) do
          assert_nil client.query(query: "query { products(first: 1) { nodes { id } } }")
        end
      end

      assert_equal :graphql_error, client.last_error[:type]
      assert_equal 1, client.last_error[:graphql_error_count]
      assert_includes logger.warnings.join("\n"), "graphql_error_count"
    end

    private

    def with_logger(logger)
      original_logger = Rails.logger
      Rails.logger = logger
      yield
    ensure
      Rails.logger = original_logger
    end

    def with_http_start(callable)
      http_singleton = Net::HTTP.singleton_class
      original_start = Net::HTTP.method(:start)
      http_singleton.define_method(:start, callable)
      yield
    ensure
      http_singleton.define_method(:start, original_start)
    end

    def http_start_with(response)
      lambda do |*_args, &block|
        return response if block.nil?

        http = Object.new
        http.define_singleton_method(:request) { |_request| response }
        block.call(http)
      end
    end
  end
end
