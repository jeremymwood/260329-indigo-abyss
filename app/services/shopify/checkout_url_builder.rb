module Shopify
  class CheckoutUrlBuilder
    Result = Struct.new(:ok?, :url, :error, keyword_init: true)

    def initialize(store_domain: ENV["SHOPIFY_STORE_DOMAIN"])
      @store_domain = normalize_domain(store_domain)
    end

    def build(lines:)
      return failure("Checkout is unavailable until Shopify is configured.") if @store_domain.blank?

      line_tokens = lines.map do |line|
        variant_id = normalize_variant_id(line.variant_id)
        quantity = line.quantity.to_i

        return failure("Cart contains invalid items. Please remove and try again.") if variant_id.blank? || quantity <= 0

        "#{variant_id}:#{quantity}"
      end

      return failure("Your cart is empty.") if line_tokens.empty?

      Result.new(ok?: true, url: "https://#{@store_domain}/cart/#{line_tokens.join(",")}?checkout")
    end

    private

    def failure(message)
      Result.new(ok?: false, error: message)
    end

    def normalize_domain(domain)
      raw = domain.to_s.strip
      return nil if raw.blank?

      raw.sub(%r{\Ahttps?://}i, "").split("/").first
    end

    def normalize_variant_id(value)
      id = value.to_s.strip
      return nil if id.blank?

      id = id.split("/").last if id.start_with?("gid://")
      id.match?(/\A\d+\z/) ? id : nil
    end
  end
end
