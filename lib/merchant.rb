require "pry"
require "time"

class Merchant

  attr_reader :name,
              :id,
              :created_at,
              :updated_at,
              :parent

  def initialize(merchant_data, parent=nil)
              @name       = merchant_data[:name].to_s
              @id         = merchant_data[:id].to_i
              @created_at = Time.parse(merchant_data[:created_at])
              @updated_at = Time.parse(merchant_data[:updated_at])
              @parent     = parent
  end

  def items
    @parent.find_items_by_merchant_id(id)
  end

  def invoices
    @parent.find_invoices_by_merchant_id(id)
  end

  def customers
    @parent.find_customers_by_invoices(invoices).uniq
  end

  def total
    invoices.reduce(0) do |sum, invoice|
      if invoice.total.class != nil
        sum += invoice.total
      end
    end
  end

  def revenue
    invoices.reduce(0) do |total, invoice|
      if invoice.total.nil?
        total += 0
      else
        total += invoice.total
      end
    end
  end

  def single_sellers?
    true if items.length == 1
  end
end
