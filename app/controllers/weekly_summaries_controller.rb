class WeeklySummariesController < ApplicationController

  def show
    @date = if params[:date].present?
              begin
                Date.parse(params[:date].to_s)
              rescue ArgumentError
                Date.current
              end
            else
              Date.current
            end

    @start_date = @date.beginning_of_week
    @end_date   = @date.end_of_week

    @scope = params[:scope] == "family" && current_user.household.present? ? "family" : "personal"
    @household = current_user.household

    logs_source = if @scope == "family"
                    @household.meal_logs
                  else
                    current_user.meal_logs
                  end

    @week_logs     = logs_source.where(date: @start_date..@end_date)
    @home_meals    = @week_logs.at_home.count
    @street_meals  = @week_logs.on_street.meals_only.count
    @micro_count   = @week_logs.micro_expenses.count

    @street_spent  = @week_logs.on_street.sum { |m| m.amount || 0.0 }
    @bcv_rate      = PaymentSetting.current.usd_to_bs_rate
    @street_spent_bs = (@street_spent * @bcv_rate).round(2)

    @micro_spent    = @week_logs.micro_expenses.sum { |m| m.amount || 0.0 }
    @micro_spent_bs = (@micro_spent * @bcv_rate).round(2)

    total_meals = @home_meals + @street_meals
    @habit_score = if total_meals.positive?
                     ((@home_meals.to_f / total_meals) * 10).round(1)
                   else
                     10.0
                   end

    @badge_info = calculate_badge(@habit_score)

    # Identificar el mayor gasto o tentación
    street_by_category = @week_logs.on_street.group(:category).sum(:amount)
    @top_temptation_category = street_by_category.max_by { |_k, v| v }&.first || "none"
    @top_temptation_amount = street_by_category[@top_temptation_category] || 0.0

    # Identificar el día estrella de la semana
    days_data = (@start_date..@end_date).map do |d|
      day_logs = @week_logs.for_date(d)
      {
        date: d,
        home: day_logs.at_home.count,
        street_spent: day_logs.on_street.sum { |m| m.amount || 0.0 }
      }
    end
    @best_day = days_data.select { |d| d[:home] > 0 && d[:street_spent].zero? }.max_by { |d| d[:home] } || days_data.max_by { |d| d[:home] }

    # Para el hogar: ranking familiar
    if @scope == "family"
      @leaderboard = @household.weekly_cook_leaderboard(@start_date)
    end
  end

  private

  def calculate_badge(score)
    if score >= 9.0
      {
        title: "Chef Supremo 👨‍🍳",
        description: "¡Disciplina de acero! La cocina de casa fue tu mayor fortaleza.",
        color_class: "from-emerald-500 to-teal-600",
        badge_bg: "bg-emerald-100 text-emerald-800"
      }
    elsif score >= 7.5
      {
        title: "Guardián del Hogar 🛡️",
        description: "Gran balance. Mantuviste los gastos de la calle a raya.",
        color_class: "from-teal-500 to-cyan-600",
        badge_bg: "bg-teal-100 text-teal-800"
      }
    elsif score >= 5.0
      {
        title: "Equilibrista Casero ⚖️",
        description: "Buen intento. Un par de comidas caseras más y subes de nivel.",
        color_class: "from-amber-500 to-orange-600",
        badge_bg: "bg-amber-100 text-amber-800"
      }
    else
      {
        title: "Amante de la Calle 🍔",
        description: "Semana agitada. ¡La próxima semana toca consentir el bolsillo en casa!",
        color_class: "from-rose-500 to-red-600",
        badge_bg: "bg-rose-100 text-rose-800"
      }
    end
  end
end
