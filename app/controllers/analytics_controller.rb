class AnalyticsController < ApplicationController
  def index
    @date = if params[:date].present?
              begin
                Date.parse(params[:date])
              rescue ArgumentError
                Date.current
              end
            else
              Date.current
            end

    # Comidas del mes seleccionado para el usuario en sesión
    @month_meals = current_user.meal_logs.for_month(@date)
    @street_meals = @month_meals.select(&:street?)
    @home_meals   = @month_meals.select(&:home?)

    @total_street_spent = @street_meals.sum { |m| m.amount || 0.0 }
    @home_count   = @home_meals.size
    @street_count = @street_meals.size
    @total_count  = @month_meals.size

    @home_ratio = @total_count.positive? ? ((@home_count.to_f / @total_count) * 100).round : 0
    @street_ratio = @total_count.positive? ? 100 - @home_ratio : 0

    @avg_street_cost = @street_count.positive? ? (@total_street_spent / @street_count).round(2) : 0.0

    # Desglose de Gastos Hormiga del Mes
    @micro_meals = @month_meals.micro_expenses
    @micro_total_spent = @micro_meals.sum { |m| m.amount || 0.0 }
    @bcv_rate = PaymentSetting.current.usd_to_bs_rate
    @micro_total_spent_bs = (@micro_total_spent * @bcv_rate).round(2)
    @potential_savings = (@micro_total_spent * 0.35).round(2)
    @potential_savings_bs = (@potential_savings * @bcv_rate).round(2)

    # Top categorías de gastos hormiga
    @micro_categories = MealLog::CATEGORIES.reject { |c| c == "meal" }.map do |cat|
      cat_items = @micro_meals.select { |m| m.category == cat }
      spent = cat_items.sum { |m| m.amount || 0.0 }
      {
        category: cat,
        label: MealLog::CATEGORY_LABELS[cat] || cat.humanize,
        icon: MealLog::CATEGORY_ICONS[cat] || "💸",
        count: cat_items.size,
        total: spent,
        total_bs: (spent * @bcv_rate).round(2)
      }
    end.select { |c| c[:count].positive? }.sort_by { |c| -c[:total] }

    # Top lugares frecuentados en la calle
    @top_places = @street_meals
                  .group_by { |m| m.place_name.presence || "Sin especificar" }
                  .map { |place, items| { place: place, count: items.size, total: items.sum { |i| i.amount || 0.0 } } }
                  .sort_by { |item| -item[:total] }
                  .first(5)

    # Datos para gráficos
    # 1. Gráfico Dona: Conteo Casa vs Calle
    @donut_chart_data = {
      labels: ["En Casa (#{home_count_label})", "En la Calle (#{street_count_label})"],
      datasets: [{
        data: [@home_count, @street_count],
        backgroundColor: ["#10B981", "#F59E0B"],
        borderWidth: 0
      }]
    }

    # 2. Desglose de Gasto en Calle por tipo de comida (Desayuno, Almuerzo, Cena, Snack)
    types = %w[breakfast lunch dinner snack]
    type_labels = ["Desayuno", "Almuerzo", "Cena", "Snack"]

    street_by_type = types.map { |t| @street_meals.select { |m| m.meal_type == t }.sum { |m| m.amount || 0.0 } }

    @type_chart_data = {
      labels: type_labels,
      datasets: [
        {
          label: "Gastado en la Calle ($)",
          data: street_by_type,
          backgroundColor: ["#FBBF24", "#F59E0B", "#EF4444", "#8B5CF6"]
        }
      ]
    }

    # 3. Histórico de Gasto de los últimos 6 meses
    six_months = (0..5).to_a.reverse.map { |i| @date.prev_month(i) }
    month_labels = six_months.map { |m| "#{ApplicationHelper::MESES_ABBR[m.month - 1]} #{m.year}" }

    street_trend = six_months.map do |m|
      current_user.meal_logs.for_month(m).select(&:street?).sum { |ml| ml.amount || 0.0 }
    end

    @trend_chart_data = {
      labels: month_labels,
      datasets: [
        {
          label: "Gastado en Calle ($)",
          data: street_trend,
          backgroundColor: "#F59E0B"
        }
      ]
    }
  end

  private

  def home_count_label
    "#{@home_count} #{@home_count == 1 ? 'comida' : 'comidas'}"
  end

  def street_count_label
    "#{@street_count} #{@street_count == 1 ? 'salida' : 'salidas'}"
  end
end
