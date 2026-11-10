require "test_helper"

class MealLogTest < ActiveSupport::TestCase
  test "validates required meal_type and location" do
    log = MealLog.new(date: Date.current)
    assert_not log.valid?
    assert log.errors[:meal_type].any?
    assert log.errors[:location].any?
  end

  test "calculates home savings against benchmark cost" do
    UserSetting.current.update!(benchmark_street_cost: 15.0)
    home_log = MealLog.create!(date: Date.current, meal_type: "lunch", location: "home", amount: 0.0)
    assert_equal 15.0, home_log.savings

    home_log_with_cost = MealLog.create!(date: Date.current, meal_type: "dinner", location: "home", amount: 3.50)
    assert_equal 11.50, home_log_with_cost.savings
  end

  test "street meals do not generate savings" do
    street_log = MealLog.create!(date: Date.current, meal_type: "lunch", location: "street", amount: 16.0)
    assert_equal 0.0, street_log.savings
  end

  test "convierte automaticamente monto en Bolivares a Dolares usando tasa BCV" do
    bcv_rate = 897.54
    PaymentSetting.current.update!(usd_to_bs_rate: bcv_rate)

    log = MealLog.create!(
      date: Date.current,
      category: "snack",
      currency: "VES",
      original_amount: 1795.08,
      bcv_rate: bcv_rate,
      note: "2 empanadas y café"
    )

    assert_equal 2.00, log.amount
    assert_equal 1795.08, log.original_amount
    assert_equal "VES", log.currency
    assert log.micro_expense?
    assert_includes log.formatted_dual_amount, "1795.08 Bs."
    assert_includes log.formatted_dual_amount, "$2.00 USD"
  end

  test "registra gasto hormiga con categoria personalizada y default street location" do
    log = MealLog.create!(
      date: Date.current,
      category: "transport",
      currency: "USD",
      original_amount: 1.50,
      note: "Pasaje buseta"
    )

    assert_equal "transport", log.category
    assert_equal "street", log.location
    assert_equal 1.50, log.amount
    assert_equal "🚗", log.category_icon
  end
end
