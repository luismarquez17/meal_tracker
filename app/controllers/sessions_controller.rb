class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create omniauth failure]
  protect_from_forgery except: %i[omniauth]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = user.admin? ? "¡Bienvenido Super Administrador Luis!" : "¡Hola de nuevo, #{user.name}!"
      
      if user.admin?
        redirect_to admin_dashboard_path
      else
        redirect_back_or(root_path)
      end
    else
      flash.now[:alert] = "Correo electrónico o contraseña incorrectos."
      render :new, status: :unprocessable_entity
    end
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    if auth.present?
      user = User.from_omniauth(auth)
      session[:user_id] = user.id
      flash[:notice] = "¡Sesión iniciada con Google correctamente!"
      if user.admin?
        redirect_to admin_dashboard_path
      else
        redirect_back_or(root_path)
      end
    else
      redirect_to login_path, alert: "No se pudo autenticar con Google. Inténtalo de nuevo."
    end
  end

  def failure
    error_msg = params[:message].to_s.strip
    friendly_msg = case error_msg.downcase
                   when "access_denied"
                     "Cancelaste el inicio de sesión con Google."
                   when "invalid_credentials", "invalid_client"
                     "Credenciales de Google inválidas. Verifica tu GOOGLE_CLIENT_ID y GOOGLE_CLIENT_SECRET en .env."
                   else
                     error_msg.present? ? "No se pudo completar el inicio de sesión con Google: #{error_msg.humanize}." : "No se pudo completar el inicio de sesión con Google."
                   end
    redirect_to login_path, alert: friendly_msg
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to login_path, notice: "Has cerrado sesión correctamente. ¡Hasta pronto!"
  end
end
