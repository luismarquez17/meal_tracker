namespace :bcv do
  desc "Actualiza la tasa oficial del BCV en Venezuela para el cobro en bolívares"
  task update_rate: :environment do
    puts "Sincronizando tasa oficial del BCV..."
    setting = PaymentSetting.current
    if setting.sync_bcv_rate!
      puts "✅ Tasa BCV actualizada con éxito:"
      puts "   - Tasa: #{setting.usd_to_bs_rate} Bs/USD"
      puts "   - Fuente: #{setting.rate_source}"
      puts "   - Total mensual ($2): #{setting.amount_in_bs} Bs"
    else
      puts "⚠️ No se pudo actualizar la tasa automáticamente. Se mantiene la última válida: #{setting.usd_to_bs_rate} Bs"
    end
  end
end
