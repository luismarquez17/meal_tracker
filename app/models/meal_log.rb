class MealLog < ApplicationRecord
  belongs_to :user, optional: true
  has_many :meal_reactions, dependent: :destroy
  MEAL_TYPES = %w[breakfast lunch dinner snack].freeze
  LOCATIONS = %w[home street].freeze
  CATEGORIES = %w[meal snack transport groceries services other].freeze

  MEAL_LABELS = {
    "breakfast" => "Desayuno",
    "lunch"     => "Almuerzo",
    "dinner"    => "Cena",
    "snack"     => "Snack"
  }.freeze

  MEAL_ICONS = {
    "breakfast" => "🍳",
    "lunch"     => "🥗",
    "dinner"    => "🍲",
    "snack"     => "☕"
  }.freeze

  CATEGORY_LABELS = {
    "meal"      => "Comida",
    "snack"     => "Café / Antojo",
    "transport" => "Transporte / Pasaje",
    "groceries" => "Mercado / Víveres",
    "services"  => "Recargas & Saldo",
    "other"     => "Otro Gasto"
  }.freeze

  CATEGORY_ICONS = {
    "meal"      => "🍔",
    "snack"     => "☕",
    "transport" => "🚗",
    "groceries" => "🛒",
    "services"  => "📱",
    "other"     => "💡"
  }.freeze

  LOCATION_LABELS = {
    "home"   => "En Casa",
    "street" => "En la Calle"
  }.freeze

  LOCATION_ICONS = {
    "home"   => "🏠",
    "street" => "🍔"
  }.freeze

  validates :date, presence: true
  validates :meal_type, inclusion: { in: MEAL_TYPES }, if: -> { category == "meal" }
  validates :location, inclusion: { in: LOCATIONS }
  validates :category, inclusion: { in: CATEGORIES }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :normalize_category_and_location
  before_validation :normalize_currency_and_amount
  before_validation :set_defaults
  before_validation :sanitize_strings

  scope :for_date, ->(d) { where(date: d) }
  scope :for_month, ->(d) { where(date: d.beginning_of_month..d.end_of_month) }
  scope :at_home, -> { where(location: "home") }
  scope :on_street, -> { where(location: "street") }
  scope :meals_only, -> { where(category: "meal") }
  scope :micro_expenses, -> { where.not(category: "meal") }
  scope :for_category, ->(cat) { where(category: cat) }
  scope :recent_first, -> { order(date: :desc, created_at: :desc) }

  def home?
    location == "home"
  end

  def street?
    location == "street"
  end

  def micro_expense?
    category != "meal"
  end

  def human_meal_type
    MEAL_LABELS[meal_type] || meal_type.to_s.humanize
  end

  def human_category
    CATEGORY_LABELS[category] || category.to_s.humanize
  end

  def category_icon
    CATEGORY_ICONS[category] || "💸"
  end

  def human_location
    LOCATION_LABELS[location] || location.to_s.humanize
  end

  def meal_icon
    MEAL_ICONS[meal_type] || "🍽️"
  end

  def location_icon
    LOCATION_ICONS[location] || ""
  end

  def current_bcv_rate
    bcv_rate.presence || PaymentSetting.current.usd_to_bs_rate
  end

  def amount_in_bs
    if currency == "VES" && original_amount.present?
      original_amount.to_f
    else
      (amount.to_f * current_bcv_rate).round(2)
    end
  end

  def formatted_dual_amount
    return "$0.00" if amount.nil? || amount.zero?

    if currency == "VES"
      "#{sprintf('%.2f', original_amount)} Bs. ($#{sprintf('%.2f', amount)} USD)"
    else
      "$#{sprintf('%.2f', amount)} USD (#{sprintf('%.2f', amount_in_bs)} Bs.)"
    end
  end

  def savings(benchmark = nil)
    return 0.0 unless home?

    ref_cost = benchmark || UserSetting.current.benchmark_street_cost || 12.0
    [ref_cost - (amount || 0.0), 0.0].max
  end

  def reactions_by_emoji
    meal_reactions.group(:emoji).count
  end

  def reacted_by?(current_user, target_emoji)
    return false if current_user.blank?

    meal_reactions.any? { |r| r.user_id == current_user.id && r.emoji == target_emoji }
  end

  private

  def normalize_category_and_location
    self.category = "meal" if category.blank?
    if micro_expense?
      self.meal_type ||= "snack"
      self.location ||= "street"
    end
  end

  def normalize_currency_and_amount
    self.currency = "USD" if currency.blank?
    self.bcv_rate ||= PaymentSetting.current.usd_to_bs_rate

    # Si se especificó original_amount
    if original_amount.present? && original_amount.to_f > 0
      rate = bcv_rate.to_f > 0 ? bcv_rate.to_f : 897.54
      if currency == "VES"
        self.amount = (original_amount.to_f / rate).round(2)
      else
        self.amount = original_amount.to_f.round(2)
      end
    elsif amount.present? && original_amount.blank?
      self.original_amount = amount
    end
  end

  def set_defaults
    self.amount ||= 0.0 if home?
    self.date ||= Date.current
  end

  def sanitize_strings
    self.place_name = place_name.to_s.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace) if place_name.present?
    self.note = note.to_s.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace) if note.present?
  end
end
