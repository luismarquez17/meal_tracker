class MealReactionsController < ApplicationController

  def create
    @meal_log = MealLog.find(params[:meal_log_id])
    emoji = params[:emoji].to_s.strip

    # Verificar que el usuario tenga permiso para reaccionar (mismo hogar o propio)
    can_react = @meal_log.user == current_user ||
                (current_user.household.present? && @meal_log.user.household_id == current_user.household_id)

    unless can_react
      head :forbidden
      return
    end

    existing = @meal_log.meal_reactions.find_by(user_id: current_user.id, emoji: emoji)

    if existing.present?
      existing.destroy
    else
      @meal_log.meal_reactions.create(user: current_user, emoji: emoji)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "meal_reactions_#{@meal_log.id}",
          partial: "dashboard/meal_reactions",
          locals: { meal: @meal_log }
        )
      end
      format.html { redirect_back fallback_location: dashboard_path }
    end
  end
end
