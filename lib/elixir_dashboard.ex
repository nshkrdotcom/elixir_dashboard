defmodule ElixirDashboard do
  @moduledoc """
  A Phoenix LiveView performance monitoring dashboard for tracking slow endpoints and database queries.

  ElixirDashboard can be used in two ways:

  ## 1. As a Standalone Application (Development/Demo)

  Clone and run the project directly to explore its features:

      mix deps.get
      mix phx.server

  Visit http://localhost:4000 to see the dashboard.

  ## 2. As a Library in Your Phoenix Application

  Add to your `mix.exs`:

      def deps do
        [
          {:elixir_dashboard, "~> 0.1.0"}
        ]
      end

  Then follow the integration guide in the README.

  ## Core Modules

  When integrating as a library, you'll primarily work with:

  - `ElixirDashboard.PerformanceMonitor` - The main monitoring system
  - `ElixirDashboard.PerformanceMonitor.Store` - Data storage GenServer
  - `ElixirDashboard.PerformanceMonitor.TelemetryHandler` - Telemetry event handlers

  ## LiveView Components

  The dashboard provides these LiveView components you can mount in your app:

  - `ElixirDashboard.PerformanceLive.Endpoints` - Slow endpoints dashboard
  - `ElixirDashboard.PerformanceLive.Queries` - Slow queries dashboard

  See the integration guide for detailed setup instructions.
  """

  @doc """
  Returns the current version of ElixirDashboard.
  """
  def version, do: unquote(Mix.Project.config()[:version])
end
