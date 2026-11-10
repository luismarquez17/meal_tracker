class PaymentSetting < ApplicationRecord
  validates :monthly_price_usd, numericality: { greater_than: 0 }
  validates :usd_to_bs_rate, numericality: { greater_than: 0 }

  def self.current
    setting = first_or_create!(
      pago_movil_bank: "0102 - Banco de Venezuela",
      pago_movil_phone: "0412-1234567",
      pago_movil_id_number: "V-26123456",
      pago_movil_holder_name: "Luis Márquez",
      binance_pay_id: "87654321",
      binance_email: "luismarquezocando2006@gmail.com",
      binance_usdt_address: "TXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      binance_network: "TRC20 (Tron)",
      monthly_price_usd: 2.00,
      usd_to_bs_rate: 897.54,
      rate_source: "BCV Oficial",
      auto_update_rate: true
    )
    setting.refresh_rate_if_needed!
    setting
  end

  def needs_rate_refresh?
    return false unless auto_update_rate?
    return true if rate_updated_at.nil?
    rate_updated_at < 4.hours.ago || rate_updated_at < Time.current.beginning_of_day
  end

  def refresh_rate_if_needed!
    return unless needs_rate_refresh?
    sync_bcv_rate!
  end

  def sync_bcv_rate!
    result = BcvExchangeRateService.fetch_current_rate
    if result[:success] && result[:rate].to_f > 0
      update_columns(
        usd_to_bs_rate: result[:rate],
        rate_updated_at: Time.current,
        rate_source: result[:source] || "BCV Oficial"
      )
      self.usd_to_bs_rate = result[:rate]
      self.rate_updated_at = Time.current
      self.rate_source = result[:source] || "BCV Oficial"
      true
    else
      update_columns(rate_updated_at: Time.current) if rate_updated_at.nil?
      false
    end
  rescue StandardError => e
    Rails.logger.warn("[PaymentSetting] No se pudo sincronizar la tasa BCV: #{e.message}")
    false
  end

  def amount_in_bs
    rate = usd_to_bs_rate.presence || 897.54
    (monthly_price_usd * rate).round(2)
  end

  def formatted_rate_date
    time = rate_updated_at.is_a?(String) ? Time.zone.parse(rate_updated_at) : rate_updated_at
    time ? time.strftime("%d/%m/%Y") : Date.current.strftime("%d/%m/%Y")
  rescue StandardError
    Date.current.strftime("%d/%m/%Y")
  end

  def formatted_rate_updated_at
    time = rate_updated_at.is_a?(String) ? Time.zone.parse(rate_updated_at) : rate_updated_at
    time ? time.in_time_zone("Caracas").strftime("%d/%m/%Y %I:%M %p") : "Hoy"
  rescue StandardError
    "Hoy"
  end
end
