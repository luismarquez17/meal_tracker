require "net/http"
require "json"

class BcvExchangeRateService
  # Obtiene la tasa oficial de cambio del Banco Central de Venezuela (BCV).
  # Emplea múltiples fuentes públicas con tiempo de espera reducido y tolerancia a fallos.

  SOURCES = [
    {
      name: "BCV Oficial (DolarVzla)",
      url: "https://rates.dolarvzla.com/bcv/current.json",
      parser: ->(json) {
        usd = json.dig("current", "usd")&.to_f
        date = json.dig("current", "date")
        [usd, date]
      }
    },
    {
      name: "BCV Oficial (DolarApi)",
      url: "https://ve.dolarapi.com/v1/dolares/oficial",
      parser: ->(json) {
        usd = (json["promedio"] || json["venta"] || json["compra"])&.to_f
        date = json["fechaActualizacion"]
        [usd, date]
      }
    }
  ].freeze

  def self.fetch_current_rate
    SOURCES.each do |source_config|
      begin
        uri = URI(source_config[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 4
        http.read_timeout = 4

        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "MealTracker-Venezuela/1.0"
        request["Accept"] = "application/json"

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          usd, date = source_config[:parser].call(data)

          if usd && usd > 0
            return {
              rate: usd.round(2),
              source: source_config[:name],
              date: date,
              success: true
            }
          end
        end
      rescue StandardError => e
        Rails.logger.warn("[BcvExchangeRateService] Falló consulta en #{source_config[:name]}: #{e.message}")
      end
    end

    { success: false, error: "No se pudo consultar la tasa oficial en línea." }
  end
end
