require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Usuario Test",
      email: "test.controller@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "should get dashboard index" do
    get dashboard_url
    assert_response :success
    assert_select "h1", text: /Meal/
  end

  test "should get analytics index" do
    get analytics_url
    assert_response :success
  end

  test "should create meal log via html and turbo_stream" do
    assert_difference("MealLog.count", 1) do
      post meal_logs_url, params: {
        meal_log: {
          date: Date.current,
          meal_type: "lunch",
          location: "street",
          amount: 14.50,
          place_name: "Tacos El Rey"
        }
      }
    end
    assert_redirected_to dashboard_url(date: Date.current)
  end

  test "should create meal log via turbo_stream" do
    post meal_logs_url,
         params: {
           meal_log: {
             date: Date.current,
             meal_type: "dinner",
             location: "home",
             amount: 0.0
           }
         },
         as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(turbo-stream action="replace" target="meal_slot_dinner")
    assert_includes response.body, %(turbo-stream action="replace" target="daily_kpis")
    assert_includes response.body, %(turbo-stream action="replace" target="monthly_kpis")
  end

  test "should delete meal log via turbo_stream" do
    log = @user.meal_logs.create!(date: Date.current, meal_type: "breakfast", location: "home", amount: 0.0)
    assert_difference("MealLog.count", -1) do
      delete meal_log_url(log), as: :turbo_stream
    end
    assert_response :success
    assert_includes response.body, %(turbo-stream action="replace" target="meal_slot_breakfast")
  end

  test "should create and count micro expense via turbo_stream" do
    PaymentSetting.current.update!(usd_to_bs_rate: 500.0)

    assert_difference("MealLog.count", 1) do
      post meal_logs_url,
           params: {
             meal_log: {
               date: Date.current,
               category: "snack",
               meal_type: "snack",
               location: "street",
               currency: "VES",
               original_amount: "1000.00",
               bcv_rate: "500.00",
               note: "Café con leche"
             }
           },
           as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, %(turbo-stream action="replace" target="micro_expenses_section")
    assert_includes response.body, %(turbo-stream action="replace" target="daily_kpis")
    assert_includes response.body, %(turbo-stream action="replace" target="monthly_kpis")
    assert_includes response.body, "+Hormiga"
    assert_includes response.body, "$2.00"
    assert_includes response.body, "Café con leche"
  end

  test "should render form_error turbo_stream when micro expense amount is zero" do
    assert_no_difference("MealLog.count") do
      post meal_logs_url,
           params: {
             meal_log: {
               date: Date.current,
               category: "snack",
               meal_type: "snack",
               location: "street",
               currency: "VES",
               original_amount: "0.00",
               bcv_rate: "500.00"
             }
           },
           as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_includes response.body, %(turbo-stream action="replace" target="flash_messages")
    assert_includes response.body, "El monto del gasto debe ser mayor a 0"
  end

  test "should delete micro expense via turbo_stream and update section" do
    log = @user.meal_logs.create!(
      date: Date.current,
      category: "transport",
      location: "street",
      currency: "USD",
      original_amount: 3.50
    )

    assert_difference("MealLog.count", -1) do
      delete meal_log_url(log), as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, %(turbo-stream action="replace" target="micro_expenses_section")
    assert_includes response.body, %(turbo-stream action="replace" target="daily_kpis")
    assert_includes response.body, %(turbo-stream action="replace" target="monthly_kpis")
  end
end
