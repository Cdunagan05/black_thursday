require "bigdecimal"
require "pry"
class SalesAnalyst
  attr_reader :sales_engine

  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def merchant_items(merchant_id)
    @sales_engine.find_items_by_merchant_id(merchant_id)
  end

  def merchant_items_count(merchant_id)
    @sales_engine.find_items_by_merchant_id(merchant_id).count
  end

  def merchant_invoice_count(merchant_id)
    @sales_engine.find_invoices_by_merchant_id(merchant_id).count
  end

  def merchant_count
    @sales_engine.merchant_count
  end

  def item_count
    @sales_engine.item_count
  end

  def invoice_count
    @sales_engine.invoice_count
  end

  def average_items_per_merchant
  (item_count/merchant_count.to_f).round(2)
  end

  def average_items_per_merchant_standard_deviation
    total = all_merchants.map do |merchant|
      ((merchant_items_count(merchant.id)) - average_items_per_merchant)**2
    end
    Math.sqrt(total.reduce(:+)/(total.length-1)).round(2)
  end

  def all_merchants
    @sales_engine.all_merchants
  end

  def all_items
    @sales_engine.all_items
  end

  def merchants_with_high_item_count
    standard_deviation = average_items_per_merchant_standard_deviation
    average = average_items_per_merchant
    all_merchants.find_all do |merchant|
      merchant_items_count(merchant.id) > (standard_deviation + average)
    end
  end

  def average_item_price_for_merchant(merchant_id)
    total = merchant_items(merchant_id).map do |item|
      item.unit_price
    end
    (total.reduce(:+)/total.length).round(2)
  end

  def average_average_price_per_merchant
    averages = all_merchants.map do |merchant|
      average_item_price_for_merchant(merchant.id)
    end
    (averages.reduce(:+)/all_merchants.length).round(2)
  end

  def average_item_price
    total = all_items.map do |item|
      item.unit_price
    end
    (total.reduce(:+)/total.length.to_f)
  end

  def standard_deviation_of_items
    total = all_items.map do |item|
      ((item.unit_price) - average_item_price)**2
    end
    Math.sqrt(total.reduce(:+)/(total.length-1))
  end

  def golden_items
    standard_deviation = standard_deviation_of_items
    all_items.find_all do |item|
      item.unit_price > (standard_deviation*2)
    end
  end

  def average_invoices_per_merchant
    (invoice_count/merchant_count.to_f).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    total = all_merchants.map do |merchant|
      ((merchant_invoice_count(merchant.id)) - average_invoices_per_merchant)**2
    end
    Math.sqrt(total.reduce(:+)/(total.length-1)).round(2)
  end

  def top_merchants_by_invoice_count
    standard_deviation = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    all_merchants.find_all do |merchant|
      merchant_invoice_count(merchant.id) > ((standard_deviation *2) + average)
    end
  end

  def bottom_merchants_by_invoice_count
    standard_deviation = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
        all_merchants.find_all do |merchant|
      merchant_invoice_count(merchant.id) < ((-standard_deviation *2) + average)
    end
  end

  def days_invoices_were_created
    @sales_engine.all_invoices.map do |invoice|
      invoice.created_at.strftime("%A")
    end
  end

  def number_of_invoices_per_given_day
    invoices_per_day = Hash.new 0
    days_invoices_were_created.each do |day|
      invoices_per_day[day] += 1
    end
    invoices_per_day
  end

  def average_invoices_per_day
    invoice_count/7.0
  end

  def standard_deviation_of_invoices_per_day
    total = number_of_invoices_per_given_day.map do |day, count|
      (count - average_invoices_per_day)**2
    end
    Math.sqrt(total.reduce(:+)/(total.length-1)).round(2)
  end

  def top_days_by_invoice_count
    days = number_of_invoices_per_given_day
    standard_deviation = standard_deviation_of_invoices_per_day
    average = average_invoices_per_day
    days.select do |day, count|
      day if count > (standard_deviation + average)
    end.keys
  end

  def invoice_status(status_input)
    count = @sales_engine.all_invoices.find_all do |invoice|
      invoice.status == status_input
    end
    ((count.length.to_f/invoice_count)*100).round(2)
  end

  def find_invoices_by_date(date_input)
    @sales_engine.find_invoices_by_date(date_input)
  end

  def total_revenue_by_date(date_input)
    invoices = find_invoices_by_date(date_input)
    invoice_items = invoices.map do |invoice|
      invoice.invoice_items
    end
    invoice_items.flatten!
    invoice_items.reduce(0) do |total, n|
      total += ( n.unit_price * n.quantity)
    end
  end

  def top_revenue_earners(top_amount=20)
    real_dealers = all_merchants.sort_by do |merchant|
      merchant.revenue
    end
    top_dealers = real_dealers.last(top_amount).reverse
  end

  def revenue_by_merchant(id)
    merchant = @sales_engine.find_merchant_by_id(id)
    merchant.revenue
  end

  def merchants_ranked_by_revenue
    all_merchants.sort_by do |merchant|
      merchant.revenue
    end.reverse
  end

  def merchants_with_pending_invoices
    waiting_merchants = all_merchants.find_all do |merchant|
       merchant.invoices.any? do |invoice|
          invoice.pending?
      end
    end
    waiting_merchants
  end

  def merchants_with_only_one_item
    all_merchants.find_all do |merchant|
      merchant.single_sellers?
    end
  end

  def merchants_with_only_one_item_registered_in_month(month)
    all_merchants.find_all do |merchant|
      merchant.created_at.strftime("%B") == month && merchant.items.length == 1
    end
  end

  def most_sold_item_for_merchant(merchant_id)
    our_merchant = all_merchants.find do |merchant|
      merchant.id == merchant_id
    end
    paid_invoices = our_merchant.invoices.find_all do |invoice|
      invoice.is_paid_in_full?
    end
    paid_invoice_items = paid_invoices.flat_map do |invoice|
      invoice.invoice_items
    end
    items = paid_invoice_items.group_by do |item|
      item.item_id
    end
    reduced = Hash.new{0}
    items.each do |key, value|
      reduced[key] = value.reduce(0){ |total, sumtin| total += sumtin.quantity}
    end
    max = reduced.values.max
    almost_done = reduced.select do |key,value|
      key if value == max
    end
    almost_done.keys.map do |key|
      all_items.find {|item| item.id == key}
    end
  end

  def best_item_for_merchant(merchant_id)
    our_merchant = all_merchants.find do |merchant|
      merchant.id == merchant_id
    end
    paid_invoices = our_merchant.invoices.find_all do |invoice|
      invoice.is_paid_in_full?
    end
    paid_invoice_items = paid_invoices.flat_map do |invoice|
      invoice.invoice_items
    end
    items = paid_invoice_items.group_by do |item|
      item.item_id
    end
    reduced = Hash.new{0}
    items.each do |key, value|
      reduced[key] =
      value.reduce(0){ |total, value| total +=(value.unit_price*value.quantity)}
    end
    max = reduced.values.max
    almost_done = reduced.select do |key,value|
      key if value == max
    end
    all_items.find do |item|
    almost_done.keys.first == item.id
    end
  end
end
