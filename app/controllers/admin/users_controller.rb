module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show extend_subscription toggle_admin]

    def index
      users = User.recent_first

      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        users = users.where("LOWER(name) LIKE ? OR LOWER(email) LIKE ?", query, query)
      end

      case params[:status]
      when "active"
        users = users.where("subscription_expires_at > ?", Time.current)
      when "expired"
        users = users.where("subscription_expires_at IS NULL OR subscription_expires_at <= ?", Time.current).where(admin: false)
      when "admin"
        users = users.where(admin: true)
      end

      @users = users
      @total_count = User.count
      @active_count = User.where("subscription_expires_at > ?", Time.current).count
    end

    def show
      @payments = @user.payments.recent_first
      @meal_logs_count = @user.meal_logs.count
    end

    def extend_subscription
      @user.activate_subscription!(30)
      redirect_back fallback_location: admin_users_path, notice: "¡Se han sumado 30 días a #{@user.name} exitosamente!"
    end

    def toggle_admin
      if @user == current_user
        redirect_back fallback_location: admin_users_path, alert: "No puedes modificar tu propio rol de administrador."
        return
      end

      @user.update!(admin: !@user.admin)
      action = @user.admin? ? "otorgado" : "revocado"
      redirect_back fallback_location: admin_users_path, notice: "Rol de administrador #{action} para #{@user.name}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
