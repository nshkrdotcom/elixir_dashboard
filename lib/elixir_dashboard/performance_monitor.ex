defmodule ElixirDashboard.PerformanceMonitor do
  @moduledoc """
  Main module for the Performance Monitor functionality.

  ## Quick Start

  Add to your application's supervision tree:

      children = [
        # ... your other children
        ElixirDashboard.PerformanceMonitor.Supervisor
      ]

  Then attach the telemetry handlers (typically in development only):

      if Mix.env() == :dev do
        ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
      end

  ## Configuration

  Configure in your config/dev.exs:

      config :elixir_dashboard,
        # Maximum number of items to keep in memory
        max_items: 100,
        # Endpoint duration threshold in milliseconds
        endpoint_threshold_ms: 100,
        # Query duration threshold in milliseconds
        query_threshold_ms: 50,
        # List of Ecto repo telemetry prefixes to monitor
        repo_prefixes: [[:my_app, :repo]]

  ## Accessing Data

      # Get slow endpoints
      ElixirDashboard.PerformanceMonitor.Store.get_slow_endpoints()

      # Get slow queries
      ElixirDashboard.PerformanceMonitor.Store.get_slow_queries()

      # Clear all data
      ElixirDashboard.PerformanceMonitor.Store.clear_all()
  """

  alias ElixirDashboard.PerformanceMonitor.{Store, TelemetryHandler, Supervisor}

  defdelegate get_slow_endpoints, to: Store
  defdelegate get_slow_queries, to: Store
  defdelegate clear_all, to: Store

  @doc """
  Attaches telemetry handlers to start monitoring.
  """
  defdelegate attach, to: TelemetryHandler

  @doc """
  Detaches telemetry handlers to stop monitoring.
  """
  defdelegate detach, to: TelemetryHandler

  @doc """
  Returns the child spec for adding to a supervision tree.
  """
  defdelegate child_spec(opts), to: Supervisor
end
