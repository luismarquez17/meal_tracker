class UserSetting < ApplicationRecord
  belongs_to :user, optional: true

  validates :benchmark_street_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :monthly_budget, numericality: { greater_than_or_equal_to: 0 }
  validates :currency_symbol, presence: true

  def self.current(user = nil)
    if user.present?
      user.setting
    else
      where(user_id: nil).first_or_create!(
        benchmark_street_cost: 12.00,
        monthly_budget: 200.00,
        currency_symbol: "$"
      )
    end
  end
end
