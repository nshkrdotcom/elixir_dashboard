import Config

# Configures the endpoint
config :elixir_dashboard, ElixirDashboardWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ElixirDashboardWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: ElixirDashboard.PubSub,
  live_view: [signing_salt: "dashboard_secret"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
