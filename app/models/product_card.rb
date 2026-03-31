class ProductCard
  attr_reader :id, :title, :description, :image_url, :price

  def initialize(id:, title:, description:, image_url:, price:)
    @id = id
    @title = title
    @description = description
    @image_url = image_url
    @price = price
  end
end
