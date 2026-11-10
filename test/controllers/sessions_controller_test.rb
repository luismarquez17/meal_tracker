require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Test User",
      email: "session.test@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )

    # Mock OmniAuth para tests
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  # --- Login con Email/Contraseña ---

  test "should render login page" do
    get login_path
    assert_response :success
    assert_select "h2", text: /Bienvenido/
  end

  test "login page has real Google OAuth button" do
    get login_path
    assert_response :success
    # El botón POST real apunta a /auth/google_oauth2
    assert_select "form[action='/auth/google_oauth2']"
    # No debe haber ningún modal simulado
    assert_select "#google-sim-modal", false, "No debe existir el modal de demo"
  end

  test "successful login redirects to dashboard" do
    post login_path, params: { email: @user.email, password: "password123" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "failed login renders form with error" do
    post login_path, params: { email: @user.email, password: "wrong" }
    assert_response :unprocessable_entity
    assert_select "div", text: /Correo electrónico o contraseña incorrectos/
  end

  test "super admin login redirects to admin dashboard" do
    admin = User.create!(
      name: "Luis Admin",
      email: User::SUPER_ADMIN_EMAIL,
      password: "123456",
      admin: true,
      subscription_status: "active",
      subscription_expires_at: 10.years.from_now
    )
    post login_path, params: { email: admin.email, password: "123456" }
    assert_redirected_to admin_dashboard_path
  end

  # --- Google OAuth Callback ---

  test "omniauth callback creates new user and redirects" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google_uid_12345",
      info: {
        email: "nuevo.usuario@gmail.com",
        name: "Nuevo Usuario",
        image: "https://lh3.googleusercontent.com/a/default-user"
      }
    )

    assert_difference("User.count", 1) do
      get "/auth/google_oauth2/callback"
    end

    user = User.find_by(email: "nuevo.usuario@gmail.com")
    assert_not_nil user
    assert_equal "Nuevo Usuario", user.name
    assert_equal "google_uid_12345", user.google_uid
    # Nuevo usuario recibe 7 días de cortesía
    assert user.subscription_expires_at > Time.current
    assert user.subscription_expires_at <= 8.days.from_now

    assert_redirected_to root_path
    assert_equal "¡Sesión iniciada con Google correctamente!", flash[:notice]
  end

  test "omniauth callback logs in existing user without duplicating" do
    existing = User.create!(
      name: "Ya Existe",
      email: "yaexiste@gmail.com",
      password: "pass1234",
      google_uid: "old_uid",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "updated_uid_99",
      info: {
        email: "yaexiste@gmail.com",
        name: "Ya Existe Actualizado",
        image: "https://lh3.googleusercontent.com/a/photo"
      }
    )

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    existing.reload
    assert_equal "updated_uid_99", existing.google_uid
    assert_redirected_to root_path
  end

  test "omniauth callback identifies super admin via google" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google_uid_admin",
      info: {
        email: User::SUPER_ADMIN_EMAIL,
        name: "Luis Super Admin",
        image: "https://lh3.googleusercontent.com/a/admin"
      }
    )

    get "/auth/google_oauth2/callback"
    user = User.find_by(email: User::SUPER_ADMIN_EMAIL)
    assert user.admin?
    assert_redirected_to admin_dashboard_path
  end

  # --- OAuth Failure ---

  test "auth failure redirects to login with friendly message" do
    get "/auth/failure", params: { message: "access_denied" }
    assert_redirected_to login_path
    follow_redirect!
    assert_select "div", text: /Cancelaste el inicio de sesión con Google/
  end

  test "auth failure with invalid_credentials shows config hint" do
    get "/auth/failure", params: { message: "invalid_credentials" }
    assert_redirected_to login_path
    follow_redirect!
    assert_select "div", text: /Credenciales de Google inválidas/
  end

  test "auth failure with unknown message shows generic error" do
    get "/auth/failure", params: { message: "something_weird" }
    assert_redirected_to login_path
    follow_redirect!
    assert_select "div", text: /No se pudo completar el inicio de sesión con Google/
  end

  # --- Logout ---

  test "logout clears session and redirects to login" do
    post login_path, params: { email: @user.email, password: "password123" }
    delete logout_path
    assert_redirected_to login_path
    follow_redirect!
    assert_response :success
  end

  # --- Registration Page ---

  test "registration page has Google OAuth button" do
    get signup_path
    assert_response :success
    assert_select "form[action='/auth/google_oauth2']"
    assert_select "span", text: "Registrarse con Google"
  end
end
