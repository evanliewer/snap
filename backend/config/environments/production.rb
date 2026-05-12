require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Use S3-compatible object storage in production if configured, else local disk.
  config.active_storage.service = ENV["S3_BUCKET"].present? ? :s3 : :local

  # Render terminates TLS in front of us.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Free Render plan: one Postgres database, so don't try to split cache/queue/cable
  # into separate DBs. Use in-process async job adapter and memory cache.
  # Move back to :solid_queue + :solid_cache_store once we move to paid tier with
  # multi-DB or a worker process.
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :async

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Default URL options for ActiveStorage / mailer.
  # Order: APP_HOST > Render-provided RENDER_EXTERNAL_HOSTNAME > generic fallback.
  app_host = ENV["APP_HOST"].presence ||
             ENV["RENDER_EXTERNAL_HOSTNAME"].presence ||
             "localhost"
  config.action_mailer.default_url_options = { host: app_host, protocol: "https" }
  Rails.application.routes.default_url_options = { host: app_host, protocol: "https" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Allow Render hosts and any custom host you configure.
  config.hosts << ".onrender.com"
  if ENV["APP_HOST"].present?
    config.hosts << ENV["APP_HOST"]
  end
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # ActionCable: iOS clients are not browsers and don't send Origin headers.
  # Token auth via params handles authentication.
  config.action_cable.disable_request_forgery_protection = true
  config.action_cable.allowed_request_origins = [%r{https?://.*}, %r{snap://.*}]
end
