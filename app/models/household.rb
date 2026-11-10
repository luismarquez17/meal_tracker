class Household < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id
  has_many :users, dependent: :nullify
  has_many :cooking_turns, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :invite_code, presence: true, uniqueness: true

  before_validation :generate_invite_code, on: :create

  def meal_logs
    MealLog.where(user_id: user_ids)
  end

  def current_turn(date = Date.current, meal_type = "dinner")
    cooking_turns.find_by(date: date, meal_type: meal_type)
  end

  def total_saved_month(date = Date.current)
    logs = meal_logs.for_month(date).at_home
    logs.sum { |m| m.savings }
  end

  def total_street_spent_month(date = Date.current)
    meal_logs.for_month(date).on_street.sum { |m| m.amount || 0.0 }
  end

  def savings_goal_progress_percentage(date = Date.current)
    return 0 if savings_goal_amount.blank? || savings_goal_amount <= 0

    saved = total_saved_month(date)
    [((saved / savings_goal_amount.to_f) * 100).round, 100].min
  end

  def savings_goal_met?(date = Date.current)
    return false if savings_goal_amount.blank? || savings_goal_amount <= 0

    total_saved_month(date) >= savings_goal_amount.to_f
  end

  # Ranking semanal de miembros que más cocinan en casa
  def weekly_cook_leaderboard(start_date = Date.current.beginning_of_week)
    end_date = start_date.end_of_week
    week_logs = meal_logs.where(date: start_date..end_date)

    users.map do |member|
      member_logs = week_logs.where(user_id: member.id)
      home_count = member_logs.at_home.count
      street_spent = member_logs.on_street.sum { |m| m.amount || 0.0 }
      saved = member_logs.at_home.sum { |m| m.savings }
      {
        user: member,
        home_count: home_count,
        street_spent: street_spent,
        saved: saved
      }
    end.sort_by { |entry| -entry[:home_count] }
  end

  private

  def generate_invite_code
    return if invite_code.present?

    loop do
      code = "CASA-#{SecureRandom.alphanumeric(4).upcase}"
      unless Household.exists?(invite_code: code)
        self.invite_code = code
        break
      end
    end
  end
end
