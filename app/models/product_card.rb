class ProductCard
  attr_reader :id, :handle, :title, :description, :image_url, :primary_image_url, :secondary_image_url, :image_urls, :price, :price_amount, :currency_code, :variant_id, :category, :designer, :size, :in_stock, :sales_rank, :created_at

  def initialize(id:, title:, description:, image_url:, price:, handle: nil, primary_image_url: nil, secondary_image_url: nil, image_urls: nil, price_amount: nil, currency_code: nil, variant_id: nil, category: nil, designer: nil, size: nil, in_stock: true, sales_rank: nil, created_at: nil)
    @id = id
    @handle = handle
    @title = title
    @description = description
    @primary_image_url = primary_image_url.presence || image_url
    @image_url = @primary_image_url
    @secondary_image_url = secondary_image_url.presence || @primary_image_url

    normalized_images = Array(image_urls).map(&:presence).compact
    normalized_images.unshift(@secondary_image_url) if @secondary_image_url.present?
    normalized_images.unshift(@primary_image_url) if @primary_image_url.present?
    @image_urls = normalized_images.uniq.first(4)
    @secondary_image_url = @image_urls[1] || @primary_image_url

    @price = price
    @price_amount = price_amount
    @currency_code = currency_code
    @variant_id = variant_id
    @category = category
    @designer = designer
    @size = size
    @in_stock = in_stock
    @sales_rank = sales_rank
    @created_at = created_at
  end
end
