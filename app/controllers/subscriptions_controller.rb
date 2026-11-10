class SubscriptionsController < ApplicationController
  def show
    @payment_setting = PaymentSetting.current
    @last_payment = current_user.payments.recent_first.first
    @payment_history = current_user.payments.recent_first
    @payment = current_user.payments.new(amount: @payment_setting.monthly_price_usd)
  end

  def create_payment
    @payment_setting = PaymentSetting.current
    @payment = current_user.payments.new(payment_params)
    @payment.amount = @payment_setting.monthly_price_usd if @payment.amount.blank? || @payment.amount <= 0
    @payment.status = "pending"

    if @payment.save
      redirect_to subscription_path, notice: "¡Reporte de pago enviado con éxito! El administrador verificará tu pago y activará tus 30 días."
    else
      @last_payment = current_user.payments.recent_first.first
      @payment_history = current_user.payments.recent_first
      flash.now[:alert] = "Error al reportar pago: #{@payment.errors.full_messages.to_sentence}"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def payment_params
    params.require(:payment).permit(:payment_method, :reference_number, :amount, :notes, :receipt)
  end
end
