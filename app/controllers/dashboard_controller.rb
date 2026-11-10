class DashboardController < ApplicationController
  def index
    @date = if params[:date].present?
              begin
                Date.parse(params[:date].to_s)
              rescue ArgumentError
                Date.current
              end
            else
              Date.current
            end

    @household = current_user.household
    @scope = params[:scope] == "family" && @household.present? ? "family" : "personal"

    source_logs = if @scope == "family"
                    @household.meal_logs
                  else
                    current_user.meal_logs
                  end

    @all_day_logs = source_logs.for_date(@date)
    @meals = @all_day_logs.meals_only

    # En vista personal mapeamos directamente a slots individuales
    # En vista familiar pueden existir múltiples comidas registradas por cada miembro
    @breakfast = @meals.find { |m| m.meal_type == "breakfast" }
    @lunch     = @meals.find { |m| m.meal_type == "lunch" }
    @dinner    = @meals.find { |m| m.meal_type == "dinner" }
    @snack     = @meals.find { |m| m.meal_type == "snack" }

    # Gastos Hormiga del día
    @micro_expenses = @all_day_logs.micro_expenses.recent_first

    # Tasa BCV Oficial actual
    @bcv_rate = PaymentSetting.current.usd_to_bs_rate

    # Totales del día (Comidas en la calle + Gastos Hormiga)
    @day_meals_spent = @meals.select(&:street?).sum { |m| m.amount || 0.0 }
    @day_micro_spent = @micro_expenses.sum { |m| m.amount || 0.0 }
    @day_street_spent = @day_meals_spent + @day_micro_spent
    @day_street_spent_bs = (@day_street_spent * @bcv_rate).round(2)

    # Métricas del mes correspondiente a @date
    @month_logs         = source_logs.for_month(@date)
    @month_meals        = @month_logs.meals_only
    @month_micro        = @month_logs.micro_expenses
    @month_street_spent = @month_logs.select(&:street?).sum { |m| m.amount || 0.0 }
    @month_street_count = @month_logs.count(&:street?)
    @month_home_count   = @month_logs.count(&:home?)
    @month_total_count  = @month_logs.size
    @home_ratio         = @month_total_count.positive? ? ((@month_home_count.to_f / @month_total_count) * 100).round : 0
    @avg_street_cost    = @month_street_count.positive? ? (@month_street_spent / @month_street_count).round(2) : 0.0
  end
end
