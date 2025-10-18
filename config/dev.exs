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

# Configure ElixirDashboard performance monitoring
config :elixir_dashboard,
  # Application name shown in UI
  app_name: "ElixirDashboard",
  # Storage backend: :tracer (ElixirTracer) or :dets (legacy)
  storage_backend: :tracer,
  # Maximum items to keep in memory
  max_items: 100,
  # Endpoint threshold in milliseconds
  endpoint_threshold_ms: 100,
  # Query threshold in milliseconds
  query_threshold_ms: 50,
  # Auto-refresh interval in milliseconds
  refresh_interval_ms: 5000,
  # Ecto repo telemetry prefixes to monitor
  repo_prefixes: [[:elixir_dashboard_web, :repo]]

# Configure ElixirTracer (storage backend for dashboard)
config :elixir_tracer,
  # Shared storage path with dashboard
  storage_path: "priv/dets",
  # Maximum items per table
  max_items: %{
    transactions: 1000,
    spans: 5000,
    errors: 500,
    metrics: 2000,
    events: 1000
  },
  # Collect full SQL queries
  collect_queries: true,
  # Collect stack traces for errors
  collect_stack_traces: true

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
