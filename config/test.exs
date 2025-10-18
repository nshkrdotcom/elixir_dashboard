import Config

# Set the environment
config :elixir_dashboard, :env, :test

# Configure the test database
config :elixir_dashboard, ElixirDashboardWeb.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "elixir_dashboard_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure Ecto repos
config :elixir_dashboard, ecto_repos: [ElixirDashboardWeb.Repo]

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
