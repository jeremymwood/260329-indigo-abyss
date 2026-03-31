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

  test "checkout_lines include variant ids and preserve invalid lines" do
    session = { cart_items: { "abyss-selvedge-14oz" => 2, "unknown" => 1 } }
    cart = SessionCart.new(session: session)
    known_product = ProductCard.new(
      id: "sample-001",
      handle: "abyss-selvedge-14oz",
      title: "Abyss Selvedge 14oz",
      description: "desc",
      image_url: "img",
      price: "USD 168.00",
      variant_id: "gid://shopify/ProductVariant/401001"
    )

    fake_catalog = Struct.new(:product) do
      def find(id)
        id == "abyss-selvedge-14oz" ? product : nil
      end
    end.new(known_product)

    checkout_lines = cart.checkout_lines(catalog: fake_catalog)

    assert_equal 2, checkout_lines.length
    assert_equal "gid://shopify/ProductVariant/401001", checkout_lines.first.variant_id
    assert_nil checkout_lines.last.variant_id
  end
end
