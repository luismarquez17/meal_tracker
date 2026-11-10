require "active_support/core_ext/integer/time"

Rails.application.configure do
  # === Configuración básica ===
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # === SSL / Hosts ===
  # Render maneja el SSL en su proxy reverso; Rails no necesita forzar SSL internamente
  # pero sí debe asumir que las peticiones llegan via HTTPS
  config.assume_ssl = true
  config.force_ssl = false  # Render termina TLS antes de llegar a Puma

  # Permitir el dominio de Render y cualquier subdominio personalizado
  config.hosts = [
    /\A.*\.onrender\.com\z/,              # *.onrender.com (Render subdominios)
    ENV.fetch("RENDER_EXTERNAL_HOSTNAME", nil)&.strip,  # Dominio real del servicio
    "localhost",
    "127.0.0.1"
  ].compact

  # === Assets ===
  config.assets.compile = false

  # === Active Storage ===
  config.active_storage.service = :local

  # === Logging ===
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # === Mailer ===
  config.action_mailer.perform_caching = false

  # === I18n ===
  config.i18n.fallbacks = true

  # === Misc ===
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end

