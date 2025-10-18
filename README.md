# Elixir Dashboard

A Phoenix LiveView performance monitoring dashboard for tracking slow endpoints and database queries during development.

[![Hex.pm](https://img.shields.io/hexpm/v/elixir_dashboard.svg)](https://hex.pm/packages/elixir_dashboard)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/elixir_dashboard)

## Two Ways to Use

### 1. 📦 As a Library in Your Phoenix App (Recommended)

Add monitoring to your existing Phoenix application:

```elixir
# mix.exs
def deps do
  [
    {:elixir_dashboard, "~> 0.1.0"}
  ]
end
```

**Quick Integration (3 steps):**

1. Add supervisor to your application.ex
2. Attach telemetry handlers
3. Add routes to your router

See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for detailed instructions.

### 2. 🚀 As a Standalone Demo Application

Run the dashboard standalone to explore its features:

```bash
git clone https://github.com/yourorg/elixir_dashboard.git
cd elixir_dashboard
mix deps.get
./start.sh
```

Visit http://localhost:4000

## Features

- **Real-time Endpoint Monitoring**: Track slow API endpoints (>100ms threshold)
- **SQL Query Tracking**: Monitor slow database queries (>50ms threshold)
- **Request Correlation**: See which endpoints triggered specific queries
- **Auto-refresh**: LiveViews update every 5 seconds
- **Color-coded Performance**: Visual indicators for severity levels
- **Zero Configuration**: Works out of the box with sensible defaults
- **Development-Only**: Automatically disabled in production

## Screenshots

### Slow Endpoints Dashboard
View your slowest API endpoints with color-coded duration indicators.

### Slow Queries Dashboard
Track database query performance and see which requests triggered them.

## How It Works

ElixirDashboard uses Phoenix's built-in `telemetry` events to capture performance metrics:

1. **Phoenix Endpoint Events** (`[:phoenix, :endpoint, :stop]`) - HTTP request timings
2. **Ecto Query Events** (`[app, :repo, :query]`) - Database query timings

Data is stored in-memory via a GenServer, keeping only the top N slowest entries for each category (default: 100).

## Configuration

All configuration is optional with sensible defaults:

```elixir
# config/dev.exs
config :elixir_dashboard,
  # Maximum items to keep in memory
  max_items: 100,
  # Endpoint duration threshold (ms)
  endpoint_threshold_ms: 100,
  # Query duration threshold (ms)
  query_threshold_ms: 50,
  # Auto-refresh interval (ms)
  refresh_interval_ms: 5000,
  # Ecto repo telemetry prefixes to monitor
  repo_prefixes: [[:my_app, :repo]]
```

## Integration with New Relic (Optional)

This tool was designed to complement the New Relic Elixir Agent. It:

- ✅ Uses the same telemetry events New Relic monitors
- ✅ Does not interfere with New Relic's data collection
- ✅ Provides immediate, local feedback during development
- ✅ Works independently - no New Relic configuration required

## Architecture

```
ElixirDashboard
├── PerformanceMonitor (Core library)
│   ├── Store (GenServer for data storage)
│   ├── TelemetryHandler (Telemetry event handlers)
│   └── Supervisor
└── PerformanceLive (LiveView components)
    ├── Endpoints (Slow endpoints dashboard)
    └── Queries (Slow queries dashboard)
```

## Development

To work on the dashboard itself:

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Start the demo server
./start.sh

# Or manually
PHX_SERVER=true iex -S mix phx.server

# Generate docs
mix docs
```

## Documentation

- [Integration Guide](INTEGRATION_GUIDE.md) - How to add to your Phoenix app
- [Setup Guide](SETUP.md) - Detailed setup and configuration
- [API Documentation](https://hexdocs.pm/elixir_dashboard) - Module documentation

## Requirements

- Elixir ~> 1.14
- Phoenix ~> 1.7
- Phoenix LiveView ~> 0.20

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Designed as a companion tool for the [New Relic Elixir Agent](https://github.com/newrelic/elixir_agent).
