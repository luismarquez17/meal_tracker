require "test_helper"

class PwaAndExportTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Usuario PWA",
      email: "pwa.user@example.com",
      password: "password123",
      subscription_status: "active",
      subscription_expires_at: 30.days.from_now
    )
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "los recursos de la PWA estan disponibles publicamente" do
    # Manifest JSON
    get "/manifest.json"
    assert_response :success
    manifest = JSON.parse(response.body)
    assert_equal "MealTracker - Control de Comidas y Ahorro", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "#059669", manifest["theme_color"]
    assert_equal "/", manifest["start_url"]
    assert manifest["icons"].any? { |i| i["sizes"] == "192x192" }
    assert manifest["icons"].any? { |i| i["sizes"] == "512x512" }

    # Service Worker
    get "/service-worker.js"
    assert_response :success
    assert_includes response.body, "meal-tracker-v1"

    # Iconos PNG y SVG
    get "/icon-192.png"
    assert_response :success
    get "/icon-512.png"
    assert_response :success
    get "/apple-touch-icon.png"
    assert_response :success
    get "/icon.svg"
    assert_response :success
  end

  test "el layout incluye metatags de PWA, banner de instalacion y script de exportacion de graficos" do
    get root_path
    assert_response :success

    # Metatags PWA en <head>
    assert_select 'link[rel="manifest"][href="/manifest.json"]'
    assert_select 'meta[name="theme-color"][content="#059669"]'
    assert_select 'meta[name="apple-mobile-web-app-capable"][content="yes"]'
    assert_select 'link[rel="apple-touch-icon"][href="/icon-192.png"]'

    # Banner y Modal de instalacion
    assert_select '[data-controller*="pwa-install"]'
    assert_select '[data-pwa-install-target="banner"]'
    assert_select '[data-pwa-install-target="modal"]'
    assert_select '[data-pwa-install-target="iosGuide"]'
    assert_select '[data-pwa-install-target="androidGuide"]'

    # Boton de instalacion en barra de navegacion
    assert_select 'button[data-action="click->pwa-install#install"]'

    # Script con downloadCanvasChart
    assert_includes response.body, "window.downloadCanvasChart = function"
  end

  test "la vista de analytics incluye encabezado ejecutivo para impresion, boton de PDF y botones de descarga PNG" do
    # Crear algunas comidas para que los graficos tengan datos
    @user.meal_logs.create!(date: Date.current, meal_type: "lunch", location: "street", amount: 12.0, place_name: "Hamburguesas")
    @user.meal_logs.create!(date: Date.current, meal_type: "dinner", location: "home", amount: 0.0)

    get analytics_path
    assert_response :success

    # Boton de Imprimir / Guardar en PDF
    assert_select 'button[onclick="window.print()"]'
    assert_includes response.body, "Imprimir / Guardar en PDF"

    # Encabezado ejecutivo para impresion
    assert_select '.print\\:block'
    assert_includes response.body, "MealTracker · Reporte Ejecutivo"
    assert_includes response.body, @user.email

    # Botones y lienzos de descarga de graficos
    assert_select '#chart-donut-canvas'
    assert_select '#chart-type-canvas'
    assert_select '#chart-trend-canvas'
    assert_select 'button[onclick*="downloadCanvasChart(\'chart-donut-canvas\'"]'
    assert_select 'button[onclick*="downloadCanvasChart(\'chart-type-canvas\'"]'
    assert_select 'button[onclick*="downloadCanvasChart(\'chart-trend-canvas\'"]'
  end

  test "el dashboard de super admin incluye boton de descarga PNG del grafico de metricas" do
    # Cambiar rol de usuario a admin
    @user.update!(admin: true)

    get admin_dashboard_path
    assert_response :success

    assert_select '#monthlyMetricsChart'
    assert_select 'button[onclick*="downloadCanvasChart(\'monthlyMetricsChart\'"]'
  end
end
