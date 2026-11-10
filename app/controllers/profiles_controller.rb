class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if params[:user][:remove_avatar] == "1"
      @user.avatar.purge_later if @user.avatar.attached?
      @user.avatar_url = nil
    end

    if @user.update(user_params)
      flash[:notice] = "Datos actualizados correctamente."
      redirect_to profile_path
    else
      flash.now[:alert] = "Hubo errores al actualizar tus datos."
      render :edit, status: :unprocessable_entity
    end
  end

  def change_password
    @user = current_user
  end

  def update_password
    @user = current_user
    if @user.authenticate(params[:user][:current_password])
      if params[:user][:new_password] == params[:user][:new_password_confirmation]
        if params[:user][:new_password].length >= 6
          @user.password = params[:user][:new_password]
          if @user.save
            flash[:notice] = "Contraseña cambiada con éxito."
            redirect_to profile_path
          else
            flash.now[:alert] = "No se pudo guardar la nueva contraseña."
            render :change_password, status: :unprocessable_entity
          end
        else
          flash.now[:alert] = "La nueva contraseña debe tener al menos 6 caracteres."
          render :change_password, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = "La confirmación de la contraseña no coincide."
        render :change_password, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Contraseña actual incorrecta."
      render :change_password, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :avatar, :avatar_url)
  end
end
