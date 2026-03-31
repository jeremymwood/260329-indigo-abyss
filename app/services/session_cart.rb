class SessionCart
  CartLine = Struct.new(:identifier, :product, :quantity, :subtotal_amount, :currency_code, keyword_init: true)
  CheckoutLine = Struct.new(:identifier, :quantity, :variant_id, keyword_init: true)

  def initialize(session:)
    @session = session
  end

  def add(product_id:, quantity: 1)
    id = normalize_id(product_id)
    return if id.blank?

    items = stored_items
    items[id] = items.fetch(id, 0) + normalize_quantity(quantity)
    write_items(items)
  end

  def update(product_id:, quantity:)
    id = normalize_id(product_id)
    return if id.blank?

    items = stored_items
    qty = normalize_update_quantity(quantity)
    if qty <= 0
      items.delete(id)
    else
      items[id] = qty
    end
    write_items(items)
  end

  def remove(product_id:)
    id = normalize_id(product_id)
    return if id.blank?

    items = stored_items
    items.delete(id)
    write_items(items)
  end

  def line_items(catalog:)
    stored_items.map do |id, quantity|
      product = catalog.find(id)
      next if product.blank?

      unit_amount = unit_price_amount(product)
      currency = product.currency_code.presence || parse_currency(product.price)
      CartLine.new(
        identifier: id,
        product: product,
        quantity: quantity,
        subtotal_amount: unit_amount * quantity,
        currency_code: currency || "USD"
      )
    end.compact
  end

  def checkout_lines(catalog:)
    stored_items.map do |id, quantity|
      product = catalog.find(id)
      CheckoutLine.new(
        identifier: id,
        quantity: quantity,
        variant_id: product&.variant_id
      )
    end
  end

  def empty?
    stored_items.empty?
  end

  private

  def stored_items
    @session[:cart_items] ||= {}
  end

  def write_items(items)
    @session[:cart_items] = items
  end

  def normalize_id(value)
    value.to_s.strip
  end

  def normalize_quantity(value)
    qty = value.to_i
    return 1 if qty <= 0

    [ qty, 50 ].min
  end

  def normalize_update_quantity(value)
    qty = value.to_i
    return 0 if qty <= 0

    [ qty, 50 ].min
  end

  def unit_price_amount(product)
    return product.price_amount.to_f if product.respond_to?(:price_amount) && product.price_amount.present?

    parse_amount(product.price)
  end

  def parse_amount(price_label)
    price_label.to_s.split.last.to_f
  end

  def parse_currency(price_label)
    price_label.to_s.split.first
  end
end
