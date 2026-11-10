# 1. Crear el Super Administrador solicitado por el usuario
admin = User.find_or_initialize_by(email: "luismarquezocando2006@gmail.com")
admin.name = "Luis Márquez (Super Admin)"
admin.password = "123456"
admin.admin = true
admin.subscription_status = "active"
admin.subscription_expires_at = 10.years.from_now
admin.save!

puts "Super Administrador listo: #{admin.email} / contraseña: #{admin.password}"

# 2. Configurar métodos de pago por defecto (Pago Móvil y Binance a $2/mes)
payment_setting = PaymentSetting.current
payment_setting.update!(
  pago_movil_bank: "0102 - Banco de Venezuela",
  pago_movil_phone: "0412-1234567",
  pago_movil_id_number: "V-26123456",
  pago_movil_holder_name: "Luis Márquez",
  binance_pay_id: "87654321",
  binance_email: "luismarquezocando2006@gmail.com",
  binance_usdt_address: "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE",
  binance_network: "TRC20 (Tron)",
  monthly_price_usd: 2.00
)

# 3. Configuración de gastos de Luis
setting = admin.setting
setting.update!(
  benchmark_street_cost: 12.00,
  monthly_budget: 220.00,
  currency_symbol: "$"
)

# 4. Crear un par de usuarios clientes para tener datos y métricas en el Panel de Super Admin
client1 = User.find_or_initialize_by(email: "ana.martinez@gmail.com")
client1.name = "Ana Martínez"
client1.password = "123456"
client1.admin = false
client1.subscription_status = "active"
client1.subscription_expires_at = 28.days.from_now
client1.created_at = 2.months.ago
client1.save!

# Pago aprobado de Ana del mes pasado ($2)
Payment.find_or_create_by!(reference_number: "PM-894721") do |p|
  p.user = client1
  p.amount = 2.00
  p.payment_method = "pago_movil"
  p.status = "approved"
  p.approved_at = 1.month.ago
  p.approved_by = admin
  p.created_at = 1.month.ago
end

# Pago aprobado de Ana de este mes ($2)
Payment.find_or_create_by!(reference_number: "PM-948102") do |p|
  p.user = client1
  p.amount = 2.00
  p.payment_method = "pago_movil"
  p.status = "approved"
  p.approved_at = 2.days.ago
  p.approved_by = admin
  p.created_at = 2.days.ago
end

# Cliente 2: Carlos con pago pendiente de $2 por Binance listo para aprobar con 1 botón
client2 = User.find_or_initialize_by(email: "carlos.mendoza@gmail.com")
client2.name = "Carlos Mendoza"
client2.password = "123456"
client2.admin = false
client2.subscription_status = "trial"
client2.subscription_expires_at = 1.day.from_now
client2.save!

Payment.find_or_create_by!(reference_number: "BIN-749201948") do |p|
  p.user = client2
  p.amount = 2.00
  p.payment_method = "binance"
  p.status = "pending"
  p.notes = "Pago de 2 USDT enviado desde cuenta Carlos M."
  p.created_at = 10.minutes.ago
end

# 5. Crear registros de comidas para Luis (para ver sus datos en el Dashboard diario y analíticas)
MealLog.where(user_id: nil).update_all(user_id: admin.id)

if admin.meal_logs.empty?
  today = Date.current
  places = ["Taquería El Pastor", "McDonald's", "Pizzería Bella", "Café Central", "Sushi Roll"]

  (1..10).to_a.reverse.each do |days_ago|
    date = today - days_ago.days
    admin.meal_logs.create!(
      date: date,
      meal_type: "breakfast",
      location: "home",
      amount: 0.0,
      note: "Huevos revueltos y café"
    )
    admin.meal_logs.create!(
      date: date,
      meal_type: "lunch",
      location: rand < 0.6 ? "home" : "street",
      amount: rand < 0.6 ? 0.0 : 14.50,
      place_name: places.sample,
      note: "Almuerzo diario"
    )
  end

  admin.meal_logs.create!(
    date: today,
    meal_type: "breakfast",
    location: "home",
    amount: 0.0,
    note: "Tostadas con aguacate y café"
  )
end

puts "Semillas listas. Usuarios: #{User.count}, Pagos: #{Payment.count}, Métodos configurados."
