module Admin
  class PaymentSettingsController < BaseController
    def edit
      @payment_setting = PaymentSetting.current
    end

    def update
      @payment_setting = PaymentSetting.current
      if @payment_setting.update(payment_setting_params)
        redirect_to edit_admin_payment_setting_path, notice: "¡Métodos de pago (Pago Móvil y Binance) actualizados correctamente! Los usuarios ya pueden ver los nuevos datos."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def sync_bcv
      @payment_setting = PaymentSetting.current
      if @payment_setting.sync_bcv_rate!
        redirect_to edit_admin_payment_setting_path, notice: "¡Tasa oficial del BCV actualizada exitosamente a #{sprintf('%.2f', @payment_setting.usd_to_bs_rate)} Bs/USD (#{sprintf('%.2f', @payment_setting.amount_in_bs)} Bs en total)!"
      else
        redirect_to edit_admin_payment_setting_path, alert: "No se pudo consultar la API del BCV en este momento. Se mantiene la tasa de #{sprintf('%.2f', @payment_setting.usd_to_bs_rate)} Bs."
      end
    end

    private

    def payment_setting_params
      params.require(:payment_setting).permit(
        :pago_movil_bank,
        :pago_movil_phone,
        :pago_movil_id_number,
        :pago_movil_holder_name,
        :binance_pay_id,
        :binance_email,
        :binance_usdt_address,
        :binance_network,
        :monthly_price_usd,
        :usd_to_bs_rate,
        :auto_update_rate
      )
    end
  end
end
