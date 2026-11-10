class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]

  def new
    redirect_to root_path if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.subscription_status = "active"
    @user.subscription_expires_at = 7.days.from_now # Prueba de cortesía

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "¡Bienvenido a MealTracker! Tienes 7 días de acceso completo."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
