require "test_helper"
require "minitest/mock"

class PaymentSettingTest < ActiveSupport::TestCase
  setup do
    @setting = PaymentSetting.current
  end

  test "calcula correctamente el monto en bolívares según la tasa" do
    @setting.monthly_price_usd = 2.00
    @setting.usd_to_bs_rate = 897.54
    assert_equal 1795.08, @setting.amount_in_bs
  end

  test "detecta cuando necesita actualizar la tasa diaria" do
    @setting.auto_update_rate = true

    # Si nunca se ha actualizado
    @setting.rate_updated_at = nil
    assert @setting.needs_rate_refresh?

    # Si se actualizó hace más de 4 horas
    @setting.rate_updated_at = 5.hours.ago
    assert @setting.needs_rate_refresh?

    # Si se actualizó hace 10 minutos (hoy)
    @setting.rate_updated_at = 10.minutes.ago
    assert_not @setting.needs_rate_refresh?

    # Si el usuario desactivó la actualización automática
    @setting.auto_update_rate = false
    assert_not @setting.needs_rate_refresh?
  end

  test "sync_bcv_rate actualiza la tasa con el servicio del BCV" do
    # Simular respuesta exitosa del servicio
    BcvExchangeRateService.stub :fetch_current_rate, { rate: 897.54, source: "BCV Oficial (Prueba)", date: "2026-11-09", success: true } do
      assert @setting.sync_bcv_rate!
      assert_equal 897.54, @setting.usd_to_bs_rate
      assert_equal "BCV Oficial (Prueba)", @setting.rate_source
      assert_not_nil @setting.rate_updated_at
      assert_equal 1795.08, @setting.amount_in_bs
    end
  end
end
