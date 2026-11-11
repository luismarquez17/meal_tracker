class MealLogsController < ApplicationController
  before_action :set_meal_log, only: %i[show edit update destroy]

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

    @filter_location = params[:location].presence
    @filter_type = params[:meal_type].presence
    @filter_period = params[:period].presence || "month"

    logs = current_user.meal_logs

    logs = case @filter_period
           when "month"
             logs.for_month(@date)
           when "all"
             logs
           when "today"
             logs.for_date(Date.current)
           else
             logs.for_month(@date)
           end

    logs = logs.where(location: @filter_location) if @filter_location.present?
    logs = logs.where(meal_type: @filter_type) if @filter_type.present?

    @meal_logs = logs.recent_first
  end

  def show
  end

  def new
    if params[:category] != "micro_expense" && !current_user.can_register_meals?
      redirect_to dashboard_path, alert: "Solo los líderes del hogar pueden registrar las comidas de la familia."
      return
    end

    @meal_log = current_user.meal_logs.new(
      date: params[:date] || Date.current,
      meal_type: params[:meal_type] || "lunch",
      location: params[:location] || "home"
    )
  end

  def edit
    if @meal_log.category == "meal" && !current_user.can_register_meals?
      redirect_to dashboard_path, alert: "Solo los líderes del hogar pueden modificar las comidas de la familia."
      return
    end
  end

  def create
    cat = meal_log_params[:category].presence || "meal"
    if cat == "meal" && !current_user.can_register_meals?
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "Solo los líderes del hogar pueden registrar las comidas de la familia." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash_messages", html: '<div id="flash_messages" class="p-3 bg-rose-50 text-rose-800 text-xs rounded-xl font-bold">Solo los líderes del hogar pueden registrar las comidas.</div>')
        end
      end
      return
    end

    if meal_log_params[:category].present? && meal_log_params[:category] != "meal"
      @meal_log = current_user.meal_logs.new(meal_log_params)
    else
      @meal_log = current_user.meal_logs.find_or_initialize_by(
        date: meal_log_params[:date],
        meal_type: meal_log_params[:meal_type],
        category: "meal"
      )
      @meal_log.assign_attributes(meal_log_params)
    end

    respond_to do |format|
      if @meal_log.save
        prepare_aggregates(@meal_log.date)
        format.turbo_stream
        format.html { redirect_to dashboard_path(date: @meal_log.date), notice: @meal_log.micro_expense? ? "¡Gasto registrado con éxito!" : "¡Comida cargada exitosamente!" }
        format.json { render :show, status: :created, location: @meal_log }
      else
        format.turbo_stream { render :form_error, status: :unprocessable_entity }
        format.html { redirect_to dashboard_path(date: @meal_log.date), alert: @meal_log.errors.full_messages.to_sentence }
        format.json { render json: @meal_log.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @meal_log.category == "meal" && !current_user.can_register_meals?
      respond_to do |format|
        format.html { redirect_to dashboard_path(date: @meal_log.date), alert: "Solo los líderes del hogar pueden modificar las comidas." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash_messages", html: '<div id="flash_messages" class="p-3 bg-rose-50 text-rose-800 text-xs rounded-xl font-bold">Solo los líderes del hogar pueden modificar las comidas.</div>')
        end
      end
      return
    end

    respond_to do |format|
      if @meal_log.update(meal_log_params)
        prepare_aggregates(@meal_log.date)
        format.turbo_stream
        format.html { redirect_to dashboard_path(date: @meal_log.date), notice: "Gasto actualizado correctamente." }
        format.json { render :show, status: :ok, location: @meal_log }
      else
        format.turbo_stream { render :form_error, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @meal_log.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @meal_log.category == "meal" && !current_user.can_register_meals?
      respond_to do |format|
        format.html { redirect_to dashboard_path(date: @meal_log.date), alert: "Solo los líderes del hogar pueden eliminar las comidas." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash_messages", html: '<div id="flash_messages" class="p-3 bg-rose-50 text-rose-800 text-xs rounded-xl font-bold">Solo los líderes del hogar pueden eliminar las comidas.</div>')
        end
      end
      return
    end

    date = @meal_log.date
    meal_type = @meal_log.meal_type
    was_micro = @meal_log.micro_expense?
    @meal_log.destroy
    prepare_aggregates(date)

    respond_to do |format|
      format.turbo_stream do
        if was_micro
          render turbo_stream: [
            turbo_stream.remove("micro_expense_#{@meal_log.id}"),
            turbo_stream.replace("daily_kpis", partial: "dashboard/daily_kpis"),
            turbo_stream.replace("monthly_kpis", partial: "dashboard/monthly_kpis")
          ]
        else
          render turbo_stream: [
            turbo_stream.replace(
              "meal_slot_#{meal_type}",
              partial: "dashboard/meal_slot",
              locals: { meal: nil, meal_type: meal_type, date: date }
            ),
            turbo_stream.replace("daily_kpis", partial: "dashboard/daily_kpis"),
            turbo_stream.replace("monthly_kpis", partial: "dashboard/monthly_kpis")
          ]
        end
      end
      format.html { redirect_to dashboard_path(date: date), notice: "Registro eliminado." }
      format.json { head :no_content }
    end
  end

  private

  def prepare_aggregates(date)
    @date = date

    @meals = current_user.meal_logs.for_date(@date)
    @day_street_spent = @meals.select(&:street?).sum { |m| m.amount || 0.0 }

    @month_meals        = current_user.meal_logs.for_month(@date)
    @month_street_spent = @month_meals.select(&:street?).sum { |m| m.amount || 0.0 }
    @month_street_count = @month_meals.count(&:street?)
    @month_home_count   = @month_meals.count(&:home?)
    @month_total_count  = @month_meals.size
    @home_ratio         = @month_total_count.positive? ? ((@month_home_count.to_f / @month_total_count) * 100).round : 0
    @avg_street_cost    = @month_street_count.positive? ? (@month_street_spent / @month_street_count).round(2) : 0.0
  end

  def set_meal_log
    if current_user.household_leader?
      @meal_log = current_user.household.meal_logs.find_by(id: params[:id]) || current_user.meal_logs.find(params[:id])
    else
      @meal_log = current_user.meal_logs.find(params[:id])
    end
  end

  def meal_log_params
    params.require(:meal_log).permit(
      :date, :meal_type, :location, :amount, :note, :place_name,
      :category, :currency, :original_amount, :bcv_rate
    )
  end
end
