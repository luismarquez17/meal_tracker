require "test_helper"

class FullFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(email: "luismarquezocando2006@gmail.com")
    unless @admin
      @admin = User.create!(
        name: "Luis Márquez (Super Admin)",
        email: "luismarquezocando2006@gmail.com",
        password: "123456",
        admin: true,
        subscription_status: "active",
        subscription_expires_at: 10.years.from_now
      )
    end
  end

  test "flujo completo: no autenticado, login admin, login cliente, reporte y aprobacion de pago" do
    # 1. No autenticado redirige a login
    get root_path
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "h2", text: /Bienvenido a Meal/

    # 2. Login como Super Admin Luis
    post login_path, params: { email: "luismarquezocando2006@gmail.com", password: "123456" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "h1", text: /Panel Super Admin/

    # 3. Super Admin accede a metricas y pagos
    get admin_payments_path
    assert_response :success
    get admin_users_path
    assert_response :success
    get edit_admin_payment_setting_path
    assert_response :success
    assert_select "h2", text: /Banco Central de Venezuela/

    # Super Admin puede sincronizar la tasa del BCV
    post sync_bcv_admin_payment_setting_path
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes flash[:notice].to_s, "Tasa oficial del BCV"

    # Logout del admin
    get logout_path
    assert_response :redirect

    # 4. Registro de un nuevo cliente
    post signup_path, params: {
      user: {
        name: "Cliente Nuevo",
        email: "cliente.nuevo@gmail.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_response :redirect
    # 4.1 Cliente registra gasto hormiga en Bolívares
    assert_difference "MealLog.count", 1 do
      post meal_logs_path, params: {
        meal_log: {
          date: Date.current,
          category: "snack",
          currency: "VES",
          original_amount: "179.51",
          note: "Cafecito en panadería"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "[data-controller~=money-mask]"
    assert_select "input#micro-display-input[placeholder='0,00']"
    assert_select "input#slot_display_breakfast[placeholder='0,00']"

    micro_log = MealLog.last
    assert_equal "snack", micro_log.category
    assert_equal "VES", micro_log.currency
    assert micro_log.amount > 0

    # 5. Cliente visita su pagina de suscripcion
    get subscription_path
    assert_response :success
    assert_select "h1", text: /Mi Suscripción/
    assert_select "[data-controller~=money-mask]"
    assert_select "#subscription_status_card"
    assert_select "h4", text: /Pago Móvil/
    assert_select "h4", text: /Binance Pay/
    assert_includes response.body, "Tasa Oficial BCV"
    assert_includes response.body, "Monto a Transferir"
    assert_includes response.body, "Bs."
    assert_select "#pago-movil-info-banner"

    # 6. Cliente reporta pago de $2.00
    assert_difference "Payment.count", 1 do
      post create_payment_subscription_path, params: {
        payment: {
          payment_method: "pago_movil",
          amount: "2.00",
          reference_number: "REF-INTEG-9988",
          notes: "Pago enviado por Banco de Venezuela"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success

    new_payment = Payment.last
    assert_equal "pending", new_payment.status
    assert_equal 2.00, new_payment.amount

    # Logout del cliente
    get logout_path
    assert_response :redirect

    # 7. Super Admin ingresa y aprueba el pago en 1 clic (+30 dias)
    post login_path, params: { email: "luismarquezocando2006@gmail.com", password: "123456" }
    follow_redirect!

    client_user = new_payment.user
    initial_expiry = client_user.subscription_expires_at

    post approve_admin_payment_path(new_payment)
    assert_response :redirect

    new_payment.reload
    client_user.reload

    assert_equal "approved", new_payment.status
    assert_equal @admin.id, new_payment.approved_by_id
    assert client_user.subscription_expires_at > initial_expiry + 29.days
  end
end
