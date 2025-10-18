# Elixir Dashboard - Setup Guide

This Phoenix LiveView application provides real-time performance monitoring for slow endpoints and database queries during development.

## Quick Start

```bash
# Install dependencies
mix deps.get

# Start the server
./start.sh

# Or manually
PHX_SERVER=true iex -S mix phx.server
```

Then visit: http://localhost:4000

## What You'll See

The dashboard provides three main views:

### 1. Homepage (`/`)
Landing page with links to all monitoring dashboards

### 2. Slow Endpoints (`/dev/performance/endpoints`)
- Real-time table of slowest API endpoints (>100ms)
- Auto-refreshes every 5 seconds
- Color-coded by severity:
  - 🟢 Green: 100-200ms
  - 🟡 Yellow: 200-500ms
  - 🟠 Orange: 500-1000ms
  - 🔴 Red: >1000ms

### 3. Slow Queries (`/dev/performance/queries`)
- Real-time list of slowest SQL queries (>50ms)
- Shows query text, parameters, and originating endpoint
- Auto-refreshes every 5 seconds
- Color-coded by severity:
  - 🟢 Green: 50-100ms
  - 🟡 Yellow: 100-200ms
  - 🟠 Orange: 200-500ms
  - 🔴 Red: >500ms

## How It Works

### Telemetry Events Monitored

The dashboard attaches to Phoenix's built-in telemetry events:

1. **`[:phoenix, :endpoint, :stop]`** - Captures HTTP endpoint timings
2. **`[app, :repo, :query]`** - Captures Ecto database query timings

### Architecture

```
ElixirDashboard.Application
├── ElixirDashboardWeb.Telemetry
├── Phoenix.PubSub
├── PerformanceMonitor.Supervisor
│   └── PerformanceMonitor.Store (GenServer)
└── ElixirDashboardWeb.Endpoint
```

### Data Flow

1. **Request arrives** → Phoenix emits `[:phoenix, :endpoint, :stop]` event
2. **TelemetryHandler captures** the event and stores path in process dictionary
3. **Database queries** triggered during request emit `[app, :repo, :query]` events
4. **TelemetryHandler captures** queries and correlates with request path
5. **Store GenServer** maintains top 100 slowest entries for each category
6. **LiveView** polls Store every 5 seconds and updates the UI

## Testing

### Generate Slow Endpoints

You can test the dashboard by creating artificial delays in your endpoints:

```elixir
# In your controller
def show(conn, _params) do
  Process.sleep(150)  # Simulate slow endpoint
  render(conn, :show)
end
```

### Generate Slow Queries

If you have Ecto in your app:

```elixir
# In your context
def list_users do
  Process.sleep(60)  # Simulate slow query
  Repo.all(User)
end
```

### Run Tests

```bash
mix test
```

## Configuration

### Adjust Performance Thresholds

Edit `lib/elixir_dashboard_web/performance_monitor/telemetry_handler.ex`:

```elixir
# Line 33: Endpoint threshold (default: 100ms)
if duration_ms > 100 do
  Store.add_slow_endpoint(...)
end

# Line 46: Query threshold (default: 50ms)
if duration_ms > 50 do
  Store.add_slow_query(...)
end
```

### Adjust Data Retention

Edit `lib/elixir_dashboard_web/performance_monitor/store.ex`:

```elixir
# Line 4: Maximum items to keep (default: 100)
@max_items 100
```

### Adjust Auto-Refresh Rate

Edit the LiveView files:

```elixir
# In lib/elixir_dashboard_web/live/performance_live/endpoints.ex
# Line 9: Refresh interval (default: 5000ms = 5 seconds)
:timer.send_interval(5000, self(), :refresh)
```

## Using with Your Phoenix App

To integrate this dashboard into your existing Phoenix application:

### Option 1: Copy the Performance Monitor Module

Copy these files to your app:

```
lib/your_app_web/performance_monitor/
├── store.ex
├── telemetry_handler.ex
└── supervisor.ex

lib/your_app_web/live/performance_live/
├── endpoints.ex
└── queries.ex
```

Then:

1. Add the supervisor to your application:
```elixir
# In lib/your_app/application.ex
children = [
  # ... your existing children
  YourAppWeb.PerformanceMonitor.Supervisor
]
```

2. Attach telemetry handlers:
```elixir
# In lib/your_app/application.ex, in start/2
if Mix.env() == :dev do
  YourAppWeb.PerformanceMonitor.TelemetryHandler.attach()
end
```

3. Add routes:
```elixir
# In lib/your_app_web/router.ex
if Mix.env() == :dev do
  scope "/dev/performance", YourAppWeb.PerformanceLive do
    pipe_through :browser
    live "/endpoints", Endpoints, :index
    live "/queries", Queries, :index
  end
end
```

### Option 2: Run as Standalone (Current Setup)

Run this dashboard as a separate application alongside your main app. Benefits:
- No code changes to your main app
- Clean separation of concerns
- Easy to remove when not needed

## Environment-Specific Behavior

### Development
- Telemetry handlers attached
- All monitoring features active
- LiveReload enabled
- Debug logging enabled

### Test
- Telemetry handlers NOT attached
- Server doesn't start by default
- Minimal logging

### Production
- Telemetry handlers NOT attached
- Dashboard routes not available
- Zero overhead

## Troubleshooting

### No data appearing?

1. Make sure the server started with `PHX_SERVER=true`
2. Verify telemetry handlers are attached (dev environment)
3. Check that your requests/queries exceed the thresholds
4. Look for error messages in the console

### Can't access the dashboard?

1. Verify the server is running on port 4000
2. Check that routes are configured correctly
3. Ensure you're in development mode (`MIX_ENV=dev`)

### Queries not correlating with endpoints?

The correlation uses the process dictionary to link queries to their triggering request. This works for:
- ✅ Synchronous queries in the same process
- ❌ Async queries in different processes (will show "N/A (Background Process)")

## Advanced Usage

### Clear Data Programmatically

```elixir
# In IEx
ElixirDashboardWeb.PerformanceMonitor.Store.clear_all()
```

### Inspect Data

```elixir
# Get all slow endpoints
endpoints = ElixirDashboardWeb.PerformanceMonitor.Store.get_slow_endpoints()

# Get all slow queries
queries = ElixirDashboardWeb.PerformanceMonitor.Store.get_slow_queries()
```

### Detach Telemetry Handlers

```elixir
# In IEx
ElixirDashboardWeb.PerformanceMonitor.TelemetryHandler.detach()
```

## Contributing

This dashboard was designed based on the specifications in `01.md`. To extend it:

1. Add new telemetry events to `telemetry_handler.ex`
2. Create new LiveView pages for visualization
3. Extend the Store GenServer with new data types
4. Add new routes in `router.ex`

## License

Companion tool for New Relic Elixir Agent development.
