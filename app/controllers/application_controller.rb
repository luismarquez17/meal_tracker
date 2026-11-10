class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?, :admin?, :current_setting

  before_action :authenticate_user!

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def current_setting
    @current_setting ||= (current_user&.setting || UserSetting.current)
  end

  private

  def authenticate_user!
    unless logged_in?
      store_location
      redirect_to login_path, alert: "Por favor inicia sesión para continuar."
    end
  end

  def require_admin!
    authenticate_user!
    return if performed?

    unless admin?
      redirect_to root_path, alert: "No tienes permisos de Super Administrador para acceder a esta área."
    end
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get? && !request.xhr?
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
end
