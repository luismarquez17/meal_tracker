require "test_helper"

class HouseholdTest < ActiveSupport::TestCase
  setup do
    @creator = User.create!(
      name: "Creador",
      email: "creator@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    @member = User.create!(
      name: "Miembro",
      email: "member@example.com",
      password: "password123",
      subscription_status: "expired",
      subscription_expires_at: 5.days.ago
    )
  end

  test "should generate unique invite code on creation" do
    household = Household.create!(name: "Familia Test", creator: @creator)
    assert household.invite_code.present?
    assert_match(/^CASA-[A-Z0-9]{4}$/, household.invite_code)
  end

  test "member inherits active subscription from household creator" do
    assert_not @member.active_subscription?

    household = Household.create!(name: "Familia Feliz", creator: @creator)
    @member.update!(household: household)

    assert @member.active_subscription?
  end

  test "calculates household savings and goal progress" do
    household = Household.create!(name: "Familia Ahorro", creator: @creator, savings_goal_amount: 50.0)
    @creator.update!(household: household)

    # Crear comidas caseras (cada una ahorra $12.00 por defecto)
    @creator.meal_logs.create!(date: Date.current, meal_type: "lunch", location: "home", amount: 0.0)
    @creator.meal_logs.create!(date: Date.current, meal_type: "dinner", location: "home", amount: 0.0)

    assert_equal 24.0, household.total_saved_month
    assert_equal 48, household.savings_goal_progress_percentage # 24 / 50 = 48%
    assert_not household.savings_goal_met?
  end

  test "meal reactions work and enforce unique emoji per user" do
    log = @creator.meal_logs.create!(date: Date.current, meal_type: "lunch", location: "home", amount: 0.0)
    reaction = log.meal_reactions.create!(user: @member, emoji: "👏")
    assert reaction.persisted?

    # No permitir duplicar la misma reacción
    duplicate = log.meal_reactions.build(user: @member, emoji: "👏")
    assert_not duplicate.valid?

    assert_equal true, log.reacted_by?(@member, "👏")
    assert_equal false, log.reacted_by?(@member, "❤️")
  end
end
