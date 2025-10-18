import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixir_dashboard, ElixirDashboardWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "289l67DMOIw7zTfjpdcgckitaFRJbBebGlsgMQNSSoUfo8BJCYoQCMsnZFE5ZLF3",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable LiveView during tests
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
