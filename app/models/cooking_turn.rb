class CookingTurn < ApplicationRecord
  belongs_to :household
  belongs_to :user

  validates :date, presence: true
  validates :meal_type, presence: true
  validates :user_id, uniqueness: { scope: [:household_id, :date, :meal_type], message: "ya tiene un turno asignado" }

  scope :for_date, ->(d) { where(date: d) }
  scope :upcoming, -> { where("date >= ?", Date.current).order(:date) }
end
