class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create omniauth failure google_dev_login]
  protect_from_forgery except: %i[omniauth google_dev_login]

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

  def google_dev_login
    # Endpoint para pruebas directas o cuando no hay GOOGLE_CLIENT_ID configurado en local
    email = params[:email].to_s.strip.downcase.presence || "usuario.google@gmail.com"
    name = params[:name].presence || email.split("@").first.humanize

    mock_auth = Struct.new(:uid, :info).new(
      "google_mock_#{SecureRandom.hex(6)}",
      Struct.new(:email, :name, :image).new(email, name, "https://lh3.googleusercontent.com/a/default-user")
    )

    user = User.from_omniauth(mock_auth)
    session[:user_id] = user.id

    flash[:notice] = "¡Sesión iniciada con cuenta Google (#{user.email})!"
    if user.admin?
      redirect_to admin_dashboard_path
    else
      redirect_to root_path
    end
  end

  def failure
    redirect_to login_path, alert: "Error en la autenticación con Google: #{params[:message].to_s.humanize}"
  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    redirect_to login_path, notice: "Has cerrado sesión correctamente. ¡Hasta pronto!"
  end
end
