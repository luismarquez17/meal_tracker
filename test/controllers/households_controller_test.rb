require "test_helper"

class HouseholdsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Luis Marquez",
      email: "luis.hh@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "should redirect to new household if user has none" do
    get household_url
    assert_redirected_to new_household_url
  end

  test "should create household" do
    assert_difference("Household.count", 1) do
      post household_url, params: {
        household: {
          name: "Los Márquez",
          savings_goal_name: "Cena especial",
          savings_goal_amount: 35.0
        },
        user_alias: "Papá"
      }
    end

    assert_redirected_to household_url
    @user.reload
    assert @user.household.present?
    assert_equal "Los Márquez", @user.household.name
    assert_equal "Papá", @user.household_alias
  end

  test "should join existing household with invite code" do
    host = User.create!(name: "Host", email: "host@example.com", password: "password123")
    household = Household.create!(name: "Casa Compartida", creator: host)

    post join_household_url, params: {
      invite_code: household.invite_code,
      user_alias: "Hijo"
    }

    assert_redirected_to household_url
    @user.reload
    assert_equal household.id, @user.household_id
    assert_equal "Hijo", @user.household_alias
  end

  test "should assign cooking turn" do
    household = Household.create!(name: "Hogar Cocina", creator: @user)
    @user.update!(household: household)

    post assign_turn_household_url, params: {
      user_id: @user.id,
      date: Date.current
    }

    turn = household.current_turn(Date.current)
    assert_not_nil turn
    assert_equal @user.id, turn.user_id
  end
end
