require "test_helper"

class WeeklySummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Usuario Wrapped",
      email: "wrapped.test@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    post login_path, params: { email: @user.email, password: "password123" }

    # Registrar comidas de la semana
    @user.meal_logs.create!(date: Date.current, meal_type: "breakfast", location: "home", amount: 0.0)
    @user.meal_logs.create!(date: Date.current, meal_type: "lunch", location: "street", amount: 8.50, place_name: "Burgers")
  end

  test "should get weekly summary show" do
    get weekly_summary_url
    assert_response :success
    assert_select "#wrapped-card"
    assert_includes response.body, "MealTracker Wrapped"
    assert_includes response.body, "Hábito de Comida"
  end

  test "should get weekly summary for family scope when household present" do
    household = Household.create!(name: "Familia Wrapped", creator: @user)
    @user.update!(household: household)

    get weekly_summary_url(scope: "family")
    assert_response :success
    assert_includes response.body, "Familia Wrapped"
  end
end
