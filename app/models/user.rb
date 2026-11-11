class User < ApplicationRecord
  has_secure_password validations: false

  belongs_to :household, optional: true
  has_many :meal_logs, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :user_setting, dependent: :destroy
  has_many :meal_reactions, dependent: :destroy
  has_many :cooking_turns, dependent: :destroy
  has_one :owned_household, class_name: "Household", foreign_key: :created_by_id, dependent: :nullify
  has_one_attached :avatar

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? && google_uid.blank? }

  before_validation :normalize_email
  before_create :check_admin_role
  after_create :create_default_setting

  SUPER_ADMIN_EMAIL = "luismarquezocando2006@gmail.com".freeze

  scope :recent_first, -> { order(created_at: :desc) }

  def self.from_omniauth(auth)
    email = auth.info.email.to_s.strip.downcase
    user = find_or_initialize_by(email: email)

    user.name = auth.info.name.presence || user.name.presence || email.split("@").first.humanize
    user.avatar_url = auth.info.image if auth.info.image.present?
    user.google_uid = auth.uid

    if email == SUPER_ADMIN_EMAIL
      user.admin = true
      user.subscription_status = "active"
      user.subscription_expires_at = 10.years.from_now
    elsif user.new_record?
      user.subscription_status = "active"
      user.subscription_expires_at = 7.days.from_now # Período de prueba de bienvenida de 7 días
    end

    user.save!
    user
  end

  def admin?
    admin == true || email.to_s.downcase == SUPER_ADMIN_EMAIL
  end

  def active_subscription?
    return true if admin?
    if subscription_expires_at.present? && subscription_expires_at > Time.current
      return true
    end

    # Beneficio Familiar: Si algún miembro o líder del hogar tiene suscripción activa, cubre a toda la familia
    if household.present?
      if household.creator.present? && household.created_by_id != id
        return true if household.creator.admin? || (household.creator.subscription_expires_at.present? && household.creator.subscription_expires_at > Time.current)
      end

      return household.users.where.not(id: id).any? do |u|
        u.admin? || (u.subscription_expires_at.present? && u.subscription_expires_at > Time.current)
      end
    end

    false
  end

  def display_name
    household_alias.presence || name.presence || email.split("@").first.titleize
  end

  def profile_avatar_image
    return avatar if avatar.attached?
    avatar_url.presence || "/default_avatar.svg"
  end

  def household_creator?
    household.present? && household.created_by_id == id
  end

  def household_leader?
    household.present? && household_role.in?(%w[leader creator])
  end

  def household_member?
    household.present? && !household_leader?
  end

  def can_register_meals?
    household.blank? || household_leader?
  end

  def role_badge_emoji
    return "👑" if household_leader?
    return "👤" if household_member?
    nil
  end

  def role_label
    return "Líder" if household_leader?
    return "Miembro" if household_member?
    "Individual"
  end

  def days_left_in_subscription
    return 999 if admin?
    return 0 if subscription_expires_at.blank? || subscription_expires_at <= Time.current

    ((subscription_expires_at - Time.current) / 1.day).ceil
  end

  def subscription_status_label
    return "Super Admin" if admin?
    return "Activa" if active_subscription?
    return "Vencida" if subscription_expires_at.present?

    "Inactiva"
  end

  def activate_subscription!(days = 30)
    base_time = (subscription_expires_at.present? && subscription_expires_at > Time.current) ? subscription_expires_at : Time.current
    self.subscription_expires_at = base_time + days.days
    self.subscription_status = "active"
    save!
  end

  def setting
    user_setting || create_user_setting(
      benchmark_street_cost: 12.00,
      monthly_budget: 200.00,
      currency_symbol: "$"
    )
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def check_admin_role
    if email == SUPER_ADMIN_EMAIL
      self.admin = true
      self.subscription_status = "active"
      self.subscription_expires_at = 10.years.from_now
    elsif subscription_expires_at.blank?
      # Nuevos usuarios reciben 7 días de cortesía inicial
      self.subscription_status = "active"
      self.subscription_expires_at = 7.days.from_now
    end
  end

  def create_default_setting
    setting
  end
end
