import Config

# Set the environment
config :elixir_dashboard, :env, :dev

# Configure the demo database
config :elixir_dashboard, ElixirDashboardWeb.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "elixir_dashboard_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure Ecto repos
config :elixir_dashboard, ecto_repos: [ElixirDashboardWeb.Repo]

# Configure repo telemetry prefix for monitoring
config :elixir_dashboard,
  repo_prefixes: [[:elixir_dashboard_web, :repo]]

# For development, we disable any cache and enable
# debugging and code reloading.
config :elixir_dashboard, ElixirDashboardWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "mLKYHiS8euofzvJQCnezqW9FJQW9W8bRX4SOQVIFNug0ltVkb4u9J/bTo3jf7cI/",
  watchers: []

# Watch static and templates for browser reloading.
config :elixir_dashboard, ElixirDashboardWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/elixir_dashboard_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :elixir_dashboard, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include HEEx debug annotations as HTML comments in rendered markup
  debug_heex_annotations: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
