module Admin
  class PaymentsController < BaseController
    before_action :set_payment, only: %i[approve reject]

    def index
      @filter_status = params[:status].presence || "pending"
      payments = Payment.includes(:user, :approved_by).recent_first

      @payments = case @filter_status
                  when "pending"  then payments.pending
                  when "approved" then payments.approved
                  when "rejected" then payments.rejected
                  else payments
                  end

      @pending_count = Payment.pending.count
      @approved_count = Payment.approved.count
      @rejected_count = Payment.rejected.count
    end

    def approve
      @payment.approve!(current_user)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("payment_row_#{@payment.id}"),
            turbo_stream.replace("admin_pending_badge", partial: "admin/payments/pending_badge", locals: { count: Payment.pending.count })
          ]
        end
        format.html { redirect_back fallback_location: admin_payments_path, notice: "¡Pago aprobado con éxito! Se activaron 30 días de suscripción para #{@payment.user.name}." }
      end
    end

    def reject
      @payment.reject!(current_user, params[:reason])

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("payment_row_#{@payment.id}"),
            turbo_stream.replace("admin_pending_badge", partial: "admin/payments/pending_badge", locals: { count: Payment.pending.count })
          ]
        end
        format.html { redirect_back fallback_location: admin_payments_path, alert: "El pago fue marcado como rechazado." }
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end
  end
end
