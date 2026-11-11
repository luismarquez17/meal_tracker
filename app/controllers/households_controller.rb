class HouseholdsController < ApplicationController
  before_action :set_household, only: %i[show update_goal assign_turn leave promote_member demote_member remove_member]
  before_action :require_household_leader!, only: %i[promote_member demote_member remove_member update_goal]

  def show
    if @household.blank?
      redirect_to new_household_path, alert: "Aún no perteneces a ningún hogar. Crea uno o únete con un código."
      return
    end

    @members = @household.users.order(:created_at)
    @cooking_turn = @household.current_turn(Date.current)
    @leaderboard = @household.weekly_cook_leaderboard
    @bcv_rate = PaymentSetting.current.usd_to_bs_rate

    month_meals = @household.meal_logs.meals_only.for_month(Date.current)
    @month_home_meals = month_meals.at_home.count
    @month_street_meals = month_meals.on_street.count
    @month_street_spent = month_meals.on_street.sum { |m| m.amount || 0.0 }
    @month_street_spent_bs = (@month_street_spent * @bcv_rate).round(2)

    # Si es líder, cargar el desglose mensual de gastos hormiga de todos los miembros
    if current_user.household_leader?
      @members_micro_expenses = @household.monthly_micro_expenses_by_member(Date.current)
    end
  end

  def new
    if current_user.household.present?
      redirect_to household_path
      return
    end

    @household = Household.new
  end

  def create
    if current_user.household.present?
      redirect_to household_path, alert: "Ya eres miembro de un hogar."
      return
    end

    @household = Household.new(household_params)
    @household.creator = current_user

    if @household.save
      current_user.update(
        household: @household,
        household_role: "leader",
        household_alias: params[:user_alias].presence || current_user.name
      )
      redirect_to household_path, notice: "¡Hogar '#{@household.name}' creado con éxito! Comparte el código con tu familia."
    else
      flash.now[:alert] = @household.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def join
    code = params[:invite_code].to_s.strip.upcase
    household = Household.find_by(invite_code: code)

    if household.present?
      current_user.update(
        household: household,
        household_role: "member",
        household_alias: params[:user_alias].presence || current_user.name
      )
      redirect_to household_path, notice: "¡Te has unido exitosamente a '#{household.name}'! 🏠"
    else
      redirect_to new_household_path, alert: "El código de invitación '#{code}' no es válido. Verifica e intenta nuevamente."
    end
  end

  def leave
    if @household.present?
      h_name = @household.name
      current_user.update(household_id: nil, household_role: "member", household_alias: nil)
      redirect_to dashboard_path, notice: "Has salido de '#{h_name}'."
    else
      redirect_to dashboard_path
    end
  end

  def promote_member
    member = @household.users.find_by(id: params[:member_id])
    if member.present?
      member.update(household_role: "leader")
      redirect_to household_path, notice: "¡#{member.display_name} ahora es Líder del hogar! 👑 Puede registrar comidas y gestionar el hogar."
    else
      redirect_to household_path, alert: "Miembro no encontrado."
    end
  end

  def demote_member
    member = @household.users.find_by(id: params[:member_id])
    if member.present?
      if @household.leaders.count <= 1 && member.household_leader?
        redirect_to household_path, alert: "No puedes cambiar el rol del único líder. Debe haber al menos un líder en el hogar."
        return
      end

      member.update(household_role: "member")
      redirect_to household_path, notice: "#{member.display_name} ahora tiene rol de Miembro 👤."
    else
      redirect_to household_path, alert: "Miembro no encontrado."
    end
  end

  def remove_member
    member = @household.users.find_by(id: params[:member_id])
    if member.present?
      member_name = member.display_name
      is_self = (member.id == current_user.id)

      if is_self && @household.leaders.count <= 1 && @household.users.count > 1
        redirect_to household_path, alert: "Eres el único líder. Promueve a otro miembro a líder antes de salir, o usa 'Abandonar Hogar'."
        return
      end

      member.update(household_id: nil, household_role: "member", household_alias: nil)

      if is_self
        redirect_to dashboard_path, notice: "Has salido de '#{@household.name}'."
      else
        redirect_to household_path, notice: "#{member_name} fue retirado del hogar."
      end
    else
      redirect_to household_path, alert: "Miembro no encontrado en el hogar."
    end
  end

  def update_goal
    if @household.present?
      if @household.update(goal_params)
        redirect_to household_path, notice: "¡Meta familiar actualizada con éxito!"
      else
        redirect_to household_path, alert: @household.errors.full_messages.to_sentence
      end
    end
  end

  def assign_turn
    if @household.present?
      date = params[:date].present? ? Date.parse(params[:date].to_s) : Date.current
      meal_type = params[:meal_type].presence || "dinner"
      user = @household.users.find_by(id: params[:user_id])

      if user.present?
        turn = @household.cooking_turns.find_or_initialize_by(date: date, meal_type: meal_type)
        turn.user = user
        turn.save!

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "cooking_turn_widget",
              partial: "dashboard/cooking_turn_widget",
              locals: { household: @household, date: date }
            )
          end
          format.html { redirect_back fallback_location: dashboard_path, notice: "¡Turno asignado a #{user.display_name}! 👨‍🍳" }
        end
      else
        redirect_back fallback_location: dashboard_path, alert: "Usuario no encontrado en el hogar."
      end
    end
  end

  private

  def set_household
    @household = current_user.household
  end

  def require_household_leader!
    unless current_user.household_leader?
      redirect_to household_path, alert: "Solo los líderes del hogar tienen permiso para realizar esta acción."
    end
  end

  def household_params
    params.require(:household).permit(:name, :savings_goal_name, :savings_goal_amount)
  end

  def goal_params
    params.require(:household).permit(:name, :savings_goal_name, :savings_goal_amount)
  end
end
