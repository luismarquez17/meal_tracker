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

    # Comidas (Desayuno, Almuerzo, Cena):
    # Si pertenece a un hogar, se muestran las comidas de la familia (registradas por los líderes)
    # Si es individual, se muestran sus propias comidas
    if @household.present?
      @meals = @household.meal_logs.meals_only.for_date(@date)
    else
      @meals = current_user.meal_logs.meals_only.for_date(@date)
    end

    @breakfast = @meals.find { |m| m.meal_type == "breakfast" }
    @lunch     = @meals.find { |m| m.meal_type == "lunch" }
    @dinner    = @meals.find { |m| m.meal_type == "dinner" }
    @snack     = @meals.find { |m| m.meal_type == "snack" }

    # Gastos Hormiga del día:
    # Cada miembro registra y ve sus propios gastos hormiga en su vista diaria
    @micro_expenses = current_user.meal_logs.micro_expenses.for_date(@date).recent_first

    # Tasa BCV Oficial actual
    @bcv_rate = PaymentSetting.current.usd_to_bs_rate

    # Totales del día (Comidas del día + Gastos Hormiga propios)
    @day_meals_spent = @meals.select(&:street?).sum { |m| m.amount || 0.0 }
    @day_micro_spent = @micro_expenses.sum { |m| m.amount || 0.0 }
    @day_street_spent = @day_meals_spent + @day_micro_spent
    @day_street_spent_bs = (@day_street_spent * @bcv_rate).round(2)

    # Métricas del mes correspondiente a @date
    month_meals = if @household.present?
                    @household.meal_logs.meals_only.for_month(@date)
                  else
                    current_user.meal_logs.meals_only.for_month(@date)
                  end
    month_micro = current_user.meal_logs.micro_expenses.for_month(@date)

    @month_street_spent = month_meals.select(&:street?).sum { |m| m.amount || 0.0 } + month_micro.sum { |m| m.amount || 0.0 }
    @month_street_count = month_meals.count(&:street?) + month_micro.count
    @month_home_count   = month_meals.count(&:home?)
    @month_total_count  = @month_home_count + @month_street_count
    @home_ratio         = @month_total_count.positive? ? ((@month_home_count.to_f / @month_total_count) * 100).round : 0
    @avg_street_cost    = @month_street_count.positive? ? (@month_street_spent / @month_street_count).round(2) : 0.0
  end
end
