module Admin
  class DashboardController < BaseController
    def index
      @total_users_count = User.where(admin: false).count
      @active_subscribers_count = User.where(admin: false).where("subscription_expires_at > ?", Time.current).count
      @expired_subscribers_count = @total_users_count - @active_subscribers_count
      
      @pending_payments = Payment.pending.includes(:user).recent_first
      @pending_count = @pending_payments.size
      
      # Métricas de ingresos
      @total_revenue = Payment.approved.sum(:amount)
      
      current_month_range = Time.current.beginning_of_month..Time.current.end_of_month
      @current_month_revenue = Payment.approved.where(approved_at: current_month_range).sum(:amount)
      
      # Desglose de los últimos 6 meses para métricas y gráficos
      @monthly_metrics = (0..5).to_a.reverse.map do |i|
        month_date = i.months.ago.to_date
        range = month_date.beginning_of_month.beginning_of_day..month_date.end_of_month.end_of_day
        
        approved_in_month = Payment.approved.where(approved_at: range)
        revenue = approved_in_month.sum(:amount)
        new_users = User.where(admin: false).where(created_at: range).count
        
        {
          label: month_date.strftime("%b %Y"),
          revenue: revenue.to_f,
          approved_count: approved_in_month.count,
          new_users: new_users
        }
      end

      # Datos para el gráfico Chart.js de ingresos mensuales
      @chart_labels = @monthly_metrics.map { |m| m[:label] }
      @chart_revenue_data = @monthly_metrics.map { |m| m[:revenue] }
      @chart_users_data = @monthly_metrics.map { |m| m[:new_users] }

      @payment_setting = PaymentSetting.current
      @recent_approved = Payment.approved.includes(:user).limit(8)
    end
  end
end
