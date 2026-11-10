require "test_helper"

class MealReactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "User React",
      email: "react@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    post login_path, params: { email: @user.email, password: "password123" }
    @log = @user.meal_logs.create!(date: Date.current, meal_type: "dinner", location: "home", amount: 0.0)
  end

  test "should toggle reaction via turbo stream" do
    assert_difference("MealReaction.count", 1) do
      post meal_log_meal_reactions_url(@log, emoji: "🤤"), as: :turbo_stream
    end
    assert_response :success
    assert_includes response.body, %(turbo-stream action="replace" target="meal_reactions_#{@log.id}")

    # Presionar de nuevo debe quitar la reacción (toggle)
    assert_difference("MealReaction.count", -1) do
      post meal_log_meal_reactions_url(@log, emoji: "🤤"), as: :turbo_stream
    end
    assert_response :success
  end
end
