# Integration Guide - Adding ElixirDashboard to Your Phoenix App

This guide shows you how to integrate ElixirDashboard into your existing Phoenix application as a library.

## Installation

### Step 1: Add Dependency

Add `:elixir_dashboard` to your `mix.exs`:

```elixir
def deps do
  [
    {:elixir_dashboard, "~> 0.1.0"}
    # Or if using from a local path:
    # {:elixir_dashboard, path: "../elixir_dashboard"}
  ]
end
```

Then run:

```bash
mix deps.get
```

### Step 2: Add to Supervision Tree

In `lib/my_app/application.ex`, add the Performance Monitor supervisor to your children:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # ... your existing children (Repo, PubSub, Endpoint, etc.)

      # Add ElixirDashboard PerformanceMonitor
      ElixirDashboard.PerformanceMonitor.Supervisor
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Step 3: Attach Telemetry Handlers

Still in `lib/my_app/application.ex`, attach the telemetry handlers (recommended to do this only in development):

```elixir
def start(_type, _args) do
  children = [
    # ... children list from above
  ]

  # Attach telemetry handlers only in development
  if Mix.env() == :dev do
    ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
  end

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### Step 4: Add Routes

In `lib/my_app_web/router.ex`, add routes for the performance dashboards:

```elixir
# Only available in development
if Mix.env() == :dev do
  scope "/dev" do
    pipe_through :browser

    # ElixirDashboard routes
    live "/performance/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index
    live "/performance/queries", ElixirDashboard.PerformanceLive.Queries, :index
  end
end
```

### Step 5: Configure (Optional)

In `config/dev.exs`, add configuration:

```elixir
config :elixir_dashboard,
  # Maximum number of items to keep in memory for each category
  max_items: 100,
  # Endpoint duration threshold in milliseconds
  endpoint_threshold_ms: 100,
  # Query duration threshold in milliseconds
  query_threshold_ms: 50,
  # Auto-refresh interval in milliseconds
  refresh_interval_ms: 5000,
  # List of Ecto repo telemetry prefixes to monitor
  # Format: [[:app_name, :repo_name]]
  repo_prefixes: [[:my_app, :repo]]
```

**Important:** Make sure to configure `repo_prefixes` to match your actual Ecto repo module name(s).

For example:
- If your repo is `MyApp.Repo`, use `[[:my_app, :repo]]`
- If you have multiple repos: `[[:my_app, :repo], [:my_app, :read_repo]]`

## That's It!

Start your Phoenix server:

```bash
mix phx.server
```

Then visit:
- **Slow Endpoints:** http://localhost:4000/dev/performance/endpoints
- **Slow Queries:** http://localhost:4000/dev/performance/queries

## Advanced Usage

### Custom Layouts

You can use your app's layout for the dashboard LiveViews:

```elixir
# In router.ex
live "/performance/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index,
  layout: {MyAppWeb.Layouts, :app}
```

### Programmatic Access

Access the performance data programmatically:

```elixir
# Get all slow endpoints
endpoints = ElixirDashboard.PerformanceMonitor.get_slow_endpoints()

# Get all slow queries
queries = ElixirDashboard.PerformanceMonitor.get_slow_queries()

# Clear all data
ElixirDashboard.PerformanceMonitor.clear_all()
```

### Runtime Control

Attach/detach monitoring at runtime:

```elixir
# Start monitoring
ElixirDashboard.PerformanceMonitor.attach()

# Stop monitoring
ElixirDashboard.PerformanceMonitor.detach()
```

## Troubleshooting

### No Query Data Appearing?

Make sure you've configured `repo_prefixes` correctly in your config. The prefix should match your Ecto repo module.

To find your repo's telemetry prefix:

```elixir
# Your repo is probably something like:
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
end

# The telemetry prefix is: [:my_app, :repo]
```

Then in config/dev.exs:

```elixir
config :elixir_dashboard,
  repo_prefixes: [[:my_app, :repo]]
```

### Dashboard Not Showing Up?

1. Make sure you're in development mode (`MIX_ENV=dev`)
2. Verify the routes are added to your router
3. Check that the supervisor was added to your application
4. Ensure telemetry handlers are attached (check your logs)

### Different Port?

If your app runs on a different port, adjust the URL accordingly:

```elixir
# In config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  http: [port: 4001]

# Then visit http://localhost:4001/dev/performance/endpoints
```

## Example: Full Integration

Here's a complete example for a typical Phoenix 1.7 app:

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      # Add ElixirDashboard
      ElixirDashboard.PerformanceMonitor.Supervisor,
      MyAppWeb.Endpoint
    ]

    # Attach telemetry in dev
    if Mix.env() == :dev do
      ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
    end

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MyAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    # ... your other routes
  end

  # Dev-only routes
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      # ElixirDashboard
      live "/performance/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index
      live "/performance/queries", ElixirDashboard.PerformanceLive.Queries, :index

      # Optional: Phoenix LiveDashboard
      import Phoenix.LiveDashboard.Router
      live_dashboard "/dashboard", metrics: MyAppWeb.Telemetry
    end
  end
end
```

```elixir
# config/dev.exs
import Config

# ... your existing config ...

# ElixirDashboard configuration
config :elixir_dashboard,
  max_items: 100,
  endpoint_threshold_ms: 100,
  query_threshold_ms: 50,
  refresh_interval_ms: 5000,
  repo_prefixes: [[:my_app, :repo]]
```

That's it! You now have performance monitoring integrated into your Phoenix application.
