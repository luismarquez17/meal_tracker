require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MealTracker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.encoding = "utf-8"
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es, :en]
    
    # Permitir visualización inline de formatos modernos de imagen en ActiveStorage
    config.active_storage.content_types_allowed_inline += %w[image/webp image/heic image/heif image/avif]
    # Configurar zona horaria de Venezuela (UTC-4)
    config.time_zone = "Caracas"
    config.active_record.default_timezone = :utc
  end
end
