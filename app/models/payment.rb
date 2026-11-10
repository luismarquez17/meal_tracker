class Payment < ApplicationRecord
  METHODS = %w[pago_movil binance].freeze
  STATUSES = %w[pending approved rejected].freeze

  METHOD_LABELS = {
    "pago_movil" => "Pago Móvil",
    "binance"    => "Binance Pay / USDT"
  }.freeze

  METHOD_ICONS = {
    "pago_movil" => "📱",
    "binance"    => "🟡"
  }.freeze

  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  has_one_attached :receipt

  validates :amount, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: METHODS }
  validates :reference_number, presence: true, length: { minimum: 4, message: "debe tener al menos 4 dígitos" }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending").order(created_at: :desc) }
  scope :approved, -> { where(status: "approved").order(approved_at: :desc, created_at: :desc) }
  scope :rejected, -> { where(status: "rejected").order(updated_at: :desc) }
  scope :recent_first, -> { order(created_at: :desc) }

  after_create_commit :broadcast_new_payment_to_admin

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def human_method
    METHOD_LABELS[payment_method] || payment_method.to_s.humanize
  end

  def method_icon
    METHOD_ICONS[payment_method] || "💳"
  end

  def approve!(admin_user)
    transaction do
      update!(
        status: "approved",
        approved_at: Time.current,
        approved_by: admin_user
      )
      user.activate_subscription!(30)
    end
    broadcast_status_updates
  end

  def reject!(admin_user, reason = nil)
    update!(
      status: "rejected",
      approved_by: admin_user,
      notes: reason.presence || notes
    )
    broadcast_status_updates
  end

  private

  def broadcast_new_payment_to_admin
    # Notificación en tiempo real para el panel de Super Admin
    Turbo::StreamsChannel.broadcast_prepend_to(
      "admin_payments",
      target: "pending_payments_list",
      partial: "admin/payments/payment_row",
      locals: { payment: self }
    ) rescue nil

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_payments",
      target: "admin_pending_badge",
      partial: "admin/payments/pending_badge",
      locals: { count: Payment.pending.count }
    ) rescue nil

    Turbo::StreamsChannel.broadcast_update_to(
      "admin_payments",
      target: "admin_audio_alert",
      partial: "admin/payments/audio_alert"
    ) rescue nil
  end

  def broadcast_status_updates
    # Actualizar la fila en el panel de admin
    Turbo::StreamsChannel.broadcast_remove_to(
      "admin_payments",
      target: "payment_row_#{id}"
    ) rescue nil

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_payments",
      target: "admin_pending_badge",
      partial: "admin/payments/pending_badge",
      locals: { count: Payment.pending.count }
    ) rescue nil

    # Actualizar la tarjeta de suscripción del usuario en tiempo real
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user_id}_subscription",
      target: "subscription_status_card",
      partial: "subscriptions/status_card",
      locals: { user: user.reload, last_payment: self }
    ) rescue nil
  end
end
