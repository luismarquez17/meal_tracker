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
          name: "Los Márquez"
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

  test "creator is set as leader" do
    post household_url, params: {
      household: { name: "Familia Líder" },
      user_alias: "Jefe"
    }
    @user.reload
    assert_equal "leader", @user.household_role
    assert @user.household_leader?
    assert @user.can_register_meals?
  end

  test "joined user is set as member" do
    household = Household.create!(name: "Familia Test", creator: @user)
    child = User.create!(name: "Carlos", email: "carlos@example.com", password: "password123")
    post login_path, params: { email: child.email, password: "password123" }

    post join_household_url, params: {
      invite_code: household.invite_code,
      user_alias: "Hijo Menor"
    }
    child.reload
    assert_equal "member", child.household_role
    assert child.household_member?
    assert_not child.can_register_meals?
  end

  test "leader can promote member to leader" do
    household = Household.create!(name: "Familia Promo", creator: @user)
    @user.update!(household: household, household_role: "leader")
    child = User.create!(name: "Ana", email: "ana@example.com", password: "password123", household: household, household_role: "member")

    post promote_member_household_url(member_id: child.id)
    assert_redirected_to household_url
    child.reload
    assert_equal "leader", child.household_role
    assert child.household_leader?
  end

  test "leader can remove another member or leader" do
    household = Household.create!(name: "Familia Expulsar", creator: @user)
    @user.update!(household: household, household_role: "leader")
    member = User.create!(name: "Pedro", email: "pedro@example.com", password: "password123", household: household, household_role: "member")

    delete remove_member_household_url(member_id: member.id)
    assert_redirected_to household_url
    member.reload
    assert_nil member.household_id
  end

  test "member cannot promote other members" do
    household = Household.create!(name: "Familia No Leader", creator: @user)
    @user.update!(household: household, household_role: "leader")
    child1 = User.create!(name: "Hijo1", email: "hijo1@example.com", password: "password123", household: household, household_role: "member")
    child2 = User.create!(name: "Hijo2", email: "hijo2@example.com", password: "password123", household: household, household_role: "member")

    post login_path, params: { email: child1.email, password: "password123" }
    post promote_member_household_url(member_id: child2.id)
    assert_redirected_to household_url
    child2.reload
    assert_equal "member", child2.household_role
  end

  test "member cannot create meal but can create micro expense" do
    household = Household.create!(name: "Familia Comidas", creator: @user)
    @user.update!(household: household, household_role: "leader")
    child = User.create!(name: "HijoComida", email: "hijoc@example.com", password: "password123", household: household, household_role: "member")
    post login_path, params: { email: child.email, password: "password123" }

    # Intento de crear comida
    assert_no_difference("MealLog.count") do
      post meal_logs_path, params: {
        meal_log: {
          date: Date.current,
          meal_type: "lunch",
          location: "street",
          amount: 5.0,
          category: "meal"
        }
      }
    end
    assert_redirected_to dashboard_path

    # Creación de gasto hormiga permitida (categoría distinta de 'meal', ej. snack, transport)
    assert_difference("MealLog.count", 1) do
      post meal_logs_path, params: {
        meal_log: {
          date: Date.current,
          meal_type: "snack",
          location: "street",
          amount: 1.5,
          category: "snack",
          place_name: "Cafecito"
        }
      }
    end
    assert_redirected_to dashboard_path(date: Date.current)
  end
end
