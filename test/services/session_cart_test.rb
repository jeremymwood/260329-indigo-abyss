require "test_helper"

class SessionCartTest < ActiveSupport::TestCase
  test "add stores quantity in session" do
    session = {}
    cart = SessionCart.new(session: session)

    cart.add(product_id: "abyss-selvedge-14oz", quantity: 2)

    assert_equal({ "abyss-selvedge-14oz" => 2 }, session[:cart_items])
  end

  test "update can remove item with zero quantity" do
    session = { cart_items: { "abyss-selvedge-14oz" => 2 } }
    cart = SessionCart.new(session: session)

    cart.update(product_id: "abyss-selvedge-14oz", quantity: 0)

    assert_equal({}, session[:cart_items])
  end

  test "line_items computes subtotal from product prices" do
    session = { cart_items: { "abyss-selvedge-14oz" => 3 } }
    cart = SessionCart.new(session: session)
    product = ProductCard.new(
      id: "sample-001",
      handle: "abyss-selvedge-14oz",
      title: "Abyss Selvedge 14oz",
      description: "desc",
      image_url: "img",
      price: "USD 168.00",
      price_amount: 168.00,
      currency_code: "USD"
    )

    fake_catalog = Struct.new(:product) do
      def find(_id)
        product
      end
    end.new(product)

    line = cart.line_items(catalog: fake_catalog).first

    assert_equal 3, line.quantity
    assert_equal 504.0, line.subtotal_amount
    assert_equal "USD", line.currency_code
  end
end
