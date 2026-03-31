class ProductCard
  attr_reader :id, :handle, :title, :description, :image_url, :price, :price_amount, :currency_code, :variant_id

  def initialize(id:, title:, description:, image_url:, price:, handle: nil, price_amount: nil, currency_code: nil, variant_id: nil)
    @id = id
    @handle = handle
    @title = title
    @description = description
    @image_url = image_url
    @price = price
    @price_amount = price_amount
    @currency_code = currency_code
    @variant_id = variant_id
  end
end
