class ProductCard
  attr_reader :id, :handle, :title, :description, :image_url, :secondary_image_url, :price, :price_amount, :currency_code, :variant_id, :category, :designer, :size, :in_stock, :sales_rank, :created_at

  def initialize(id:, title:, description:, image_url:, price:, handle: nil, secondary_image_url: nil, price_amount: nil, currency_code: nil, variant_id: nil, category: nil, designer: nil, size: nil, in_stock: true, sales_rank: nil, created_at: nil)
    @id = id
    @handle = handle
    @title = title
    @description = description
    @image_url = image_url
    @secondary_image_url = secondary_image_url || image_url
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
