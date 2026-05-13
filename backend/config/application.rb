require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module Snap
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.api_only = false

    config.active_record.async_query_executor = :global_thread_pool

    config.active_storage.variant_processor = :mini_magick

    config.session_store :cookie_store, key: "_snap_session", same_site: :lax
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Rate-limit abusive clients. Definition lives in
    # config/initializers/rack_attack.rb; inserting the middleware here so
    # it's wired in early in the boot sequence.
    config.middleware.use Rack::Attack
  end
end
