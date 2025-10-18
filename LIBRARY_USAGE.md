# ElixirDashboard - Library Usage Guide

This document explains how ElixirDashboard works as both a **library** and a **standalone application**.

## The Canonical Way: Dual-Purpose Design

ElixirDashboard is architected to work seamlessly in two modes:

### 🎯 Mode 1: As a Library (Production Integration)

**When to use:** You want to add performance monitoring to your existing Phoenix application.

**How it works:**
- Core monitoring code lives in `lib/elixir_dashboard/` (library code)
- You import it like any other Hex dependency
- Add 3 things to your app: supervisor, telemetry handler, routes
- The library has minimal dependencies (just Phoenix + LiveView + Telemetry)

**File structure when used as a library:**
```
your_phoenix_app/
├── deps/
│   └── elixir_dashboard/          # Installed as dependency
│       └── lib/
│           └── elixir_dashboard/  # Only this code is used
│               ├── performance_monitor/
│               └── performance_live/
└── lib/
    └── your_app/
        └── application.ex         # Add supervisor here
```

**Integration example:**

```elixir
# Step 1: Add to mix.exs
def deps do
  [
    {:elixir_dashboard, "~> 0.1.0"}
  ]
end

# Step 2: Add to application.ex
def start(_type, _args) do
  children = [
    MyApp.Repo,
    ElixirDashboard.PerformanceMonitor.Supervisor,  # <-- Add this
    MyAppWeb.Endpoint
  ]

  if Mix.env() == :dev do
    ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
  end

  Supervisor.start_link(children, strategy: :one_for_one)
end

# Step 3: Add to router.ex
if Mix.env() == :dev do
  scope "/dev" do
    pipe_through :browser
    live "/performance/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index
    live "/performance/queries", ElixirDashboard.PerformanceLive.Queries, :index
  end
end

# Step 4: Configure in config/dev.exs
config :elixir_dashboard,
  repo_prefixes: [[:my_app, :repo]]  # Match your repo module name
```

**That's it!** Visit `http://localhost:4000/dev/performance/endpoints`

---

### 🚀 Mode 2: As a Standalone App (Development/Demo)

**When to use:** You want to explore the dashboard features before integrating, or develop/test the dashboard itself.

**How it works:**
- Clone the repo and run it directly
- Demo app lives in `lib/elixir_dashboard_web/`
- Full Phoenix application with Endpoint, Router, Controllers, etc.
- Uses the library code from `lib/elixir_dashboard/` internally

**File structure when run standalone:**
```
elixir_dashboard/
├── lib/
│   ├── elixir_dashboard/          # Library code (reusable)
│   │   ├── performance_monitor/
│   │   └── performance_live/
│   └── elixir_dashboard_web/      # Demo app (standalone only)
│       ├── controllers/
│       ├── components/
│       ├── endpoint.ex
│       └── router.ex
├── config/
├── assets/
└── priv/
```

**Running standalone:**

```bash
git clone https://github.com/yourorg/elixir_dashboard.git
cd elixir_dashboard
mix deps.get
./start.sh

# Or manually
PHX_SERVER=true iex -S mix phx.server
```

Visit `http://localhost:4000`

---

## Design Pattern: Dual Application Modules

The trick is in `mix.exs`:

```elixir
def application do
  [
    mod: application_mod(Mix.env()),
    extra_applications: [:logger, :runtime_tools]
  ]
end

# Only start the full demo app in dev/test, not when used as a library
defp application_mod(:dev), do: {ElixirDashboard.Application, []}
defp application_mod(:test), do: {ElixirDashboard.Application, []}
defp application_mod(_), do: {ElixirDashboard.LibApplication, []}
```

**When running standalone** (dev/test):
- Starts `ElixirDashboard.Application`
- This starts the full Phoenix endpoint, routers, controllers
- Acts like a complete Phoenix app

**When used as a library** (prod/in another app):
- Starts `ElixirDashboard.LibApplication`
- This is a minimal supervisor that does nothing
- Host app controls what gets started

---

## Module Organization

### Library Modules (Always Available)

These are the modules users interact with when using as a library:

```
ElixirDashboard                                    # Main module, version info
├── PerformanceMonitor                             # Public API
│   ├── Store                                      # GenServer for data
│   ├── TelemetryHandler                           # Event handlers
│   └── Supervisor                                 # Supervisor
└── PerformanceLive                                # LiveView components
    ├── Endpoints                                  # Endpoints dashboard
    └── Queries                                    # Queries dashboard
```

### Demo App Modules (Standalone Only)

These only exist/are used when running standalone:

```
ElixirDashboardWeb                                 # Demo web interface
├── Endpoint                                       # Phoenix endpoint
├── Router                                         # Routes
├── Telemetry                                      # Telemetry setup
├── Controllers                                    # Home page, etc.
├── Components                                     # UI components
└── PerformanceMonitor                             # Delegates to library
    ├── Store          → ElixirDashboard.PerformanceMonitor.Store
    ├── TelemetryHandler → ElixirDashboard.PerformanceMonitor.TelemetryHandler
    └── Supervisor     → ElixirDashboard.PerformanceMonitor.Supervisor
```

---

## Dependencies Strategy

### Core Dependencies (Required for Library)

```elixir
{:phoenix, "~> 1.7.0"},           # LiveView needs Phoenix
{:phoenix_live_view, "~> 0.20.0"}, # For dashboard UI
{:telemetry, "~> 1.0"}             # For monitoring
```

### Optional Dependencies (Demo App Only)

```elixir
{:jason, "~> 1.2", optional: true},           # JSON (host app usually has)
{:phoenix_live_dashboard, "~> 0.8", optional: true},  # Extra dashboard
{:telemetry_metrics, "~> 0.6", optional: true},       # Metrics
{:bandit, "~> 1.0", only: [:dev, :test]}              # Dev server
```

When someone adds `{:elixir_dashboard, "~> 0.1.0"}` to their app:
- They get Phoenix, LiveView, Telemetry (probably already have)
- They don't get unnecessary demo dependencies
- Minimal footprint

---

## Configuration

All configuration is optional and environment-specific:

```elixir
# config/dev.exs (in host app)
config :elixir_dashboard,
  max_items: 100,                    # How many items to keep
  endpoint_threshold_ms: 100,        # Endpoint threshold
  query_threshold_ms: 50,            # Query threshold
  refresh_interval_ms: 5000,         # Auto-refresh rate
  repo_prefixes: [[:my_app, :repo]]  # Ecto repos to monitor
```

**No configuration required for defaults!**

---

## Benefits of This Architecture

✅ **For Library Users:**
- Simple 3-step integration
- Minimal dependencies
- Works with their existing Phoenix app
- No extra configuration needed

✅ **For Development:**
- Full standalone app for testing
- Easy to demo features
- Can develop without a host app

✅ **For Maintenance:**
- Single codebase for both modes
- Demo app uses library code (dogfooding)
- Library code has no demo app dependencies

✅ **For Publishing:**
- Publishable to Hex.pm
- Clear separation of concerns
- Professional package structure

---

## Publishing to Hex

When ready to publish:

```bash
# Build and publish
mix hex.build
mix hex.publish

# Only lib/elixir_dashboard/ code gets published
# Demo app code is excluded (via mix.exs package config)
```

The `package/0` function in `mix.exs` controls what gets published:

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
  ]
end
```

This includes all of `lib/` but users of the library only need the `lib/elixir_dashboard/` modules.

---

## Summary

The **canonical way** to build a library like this is:

1. **Core library code** in a namespace (`ElixirDashboard`)
2. **Demo/dev app** in a separate namespace (`ElixirDashboardWeb`)
3. **Dual application modules** that start different things based on environment
4. **Minimal core dependencies**, optional demo dependencies
5. **Complete documentation** for both use cases

This pattern allows:
- ✅ Easy integration into existing apps (library mode)
- ✅ Standalone running for demos/development (app mode)
- ✅ Single codebase, no duplication
- ✅ Professional package structure
- ✅ Clear separation of concerns

**ElixirDashboard achieves all of this!** 🎉
