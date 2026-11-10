class SettingsController < ApplicationController
  def show
    @setting = current_user.setting
  end

  def edit
    @setting = current_user.setting
  end

  def update
    @setting = current_user.setting
    if @setting.update(setting_params)
      redirect_to setting_path, notice: "Configuración actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:user_setting).permit(:benchmark_street_cost, :monthly_budget, :currency_symbol)
  end
end
