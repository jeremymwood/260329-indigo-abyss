class ProductPage
  attr_reader :products, :next_cursor, :prev_cursor

  def initialize(products:, next_cursor:, prev_cursor:)
    @products = products
    @next_cursor = next_cursor
    @prev_cursor = prev_cursor
  end

  def empty?
    @products.empty?
  end
end
