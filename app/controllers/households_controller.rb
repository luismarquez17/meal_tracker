class HouseholdsController < ApplicationController
  before_action :set_household, only: %i[show update_goal assign_turn leave]

  def show
    if @household.blank?
      redirect_to new_household_path, alert: "Aún no perteneces a ningún hogar. Crea uno o únete con un código."
      return
    end

    @members = @household.users.order(:created_at)
    @cooking_turn = @household.current_turn(Date.current)
    @leaderboard = @household.weekly_cook_leaderboard
    @bcv_rate = PaymentSetting.current.usd_to_bs_rate
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
        household_role: "creator",
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

  def household_params
    params.require(:household).permit(:name, :savings_goal_name, :savings_goal_amount)
  end

  def goal_params
    params.require(:household).permit(:name, :savings_goal_name, :savings_goal_amount)
  end
end
