class ProductCard
  attr_reader :id, :handle, :title, :description, :image_url, :price

  def initialize(id:, title:, description:, image_url:, price:, handle: nil)
    @id = id
    @handle = handle
    @title = title
    @description = description
    @image_url = image_url
    @price = price
  end
end
