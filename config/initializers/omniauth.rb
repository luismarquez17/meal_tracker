Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"].presence || "dummy_id",
           ENV["GOOGLE_CLIENT_SECRET"].presence || "dummy_secret",
           {
             scope: "email,profile",
             prompt: "select_account",
             image_aspect_ratio: "square",
             image_size: 150
           }
end

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

# Manejo amigable de errores y cancelaciones de OAuth (ej. cuando el usuario cancela en Google)
OmniAuth.config.on_failure = proc do |env|
  SessionsController.action(:failure).call(env)
end
