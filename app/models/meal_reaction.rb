class MealReaction < ApplicationRecord
  belongs_to :meal_log
  belongs_to :user

  ALLOWED_EMOJIS = %w[👏 ❤️ 🤤 🔥 👨‍🍳].freeze

  validates :emoji, presence: true, inclusion: { in: ALLOWED_EMOJIS }
  validates :user_id, uniqueness: { scope: [:meal_log_id, :emoji], message: "ya reaccionaste con este emoji" }
end
