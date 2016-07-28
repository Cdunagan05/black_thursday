gem 'minitest', '~> 5.2'
require 'minitest/autorun'
require 'minitest/pride'
require_relative "../lib/merchant"

class MerchantTest < MiniTest::Test
  def setup
    @merchant = Merchant.new({ :id         => "12334105",
                               :name       => "Shopin1901",
                               :created_at => "12/10/10",
                               :updated_at => "12/4/11"}, self)

  end

  def test_it_holds_an_id
    assert_equal 12334105, @merchant.id
  end

  def test_it_holds_a_name
    assert_equal "Shopin1901", @merchant.name
  end

  def test_it_holds_a_parsed_created_at
    assert_equal true, @merchant.created_at.is_a?(Time)
  end

  def test_it_holdss_a_parsed_updated_at
    assert_equal true, @merchant.updated_at.is_a?(Time)
  end

  def test_it_can_return_self
    assert_equal true, @merchant.parent.is_a?(MerchantTest)
  end
end