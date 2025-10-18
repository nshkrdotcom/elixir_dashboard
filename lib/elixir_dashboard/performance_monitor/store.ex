defmodule ElixirDashboard.PerformanceMonitor.Store do
  @moduledoc """
  Storage facade that delegates to the configured storage backend.

  Supports two backends:
  - **TracerStore** (default): Uses ElixirTracer for comprehensive observability
  - **DetsStore** (legacy): Simple DETS-based storage

  Configuration:

      config :elixir_dashboard,
        max_items: 100,
        storage_backend: :tracer  # or :dets for legacy

  ## Storage Backends

  ### TracerStore (ElixirTracer)
  - Rich transaction and span data
  - Error tracking and correlation
  - Metrics aggregation
  - Distributed tracing support
  - New Relic API compatible

  ### DetsStore (Legacy)
  - Simple endpoint/query tracking
  - Minimal dependencies
  - Backward compatible
  """

  alias ElixirDashboard.PerformanceMonitor.{DetsStore, TracerStore}

  # Client API - delegates to configured backend

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(opts) do
    backend_module().start_link(opts)
  end

  def add_slow_endpoint(endpoint_data) do
    backend_module().add_slow_endpoint(endpoint_data)
  end

  def add_slow_query(query_data) do
    backend_module().add_slow_query(query_data)
  end

  def get_slow_endpoints do
    backend_module().get_slow_endpoints()
  end

  def get_slow_queries do
    backend_module().get_slow_queries()
  end

  def clear_all do
    backend_module().clear_all()
  end

  def get_stats do
    backend_module().get_stats()
  end

  # Private

  defp backend_module do
    case Application.get_env(:elixir_dashboard, :storage_backend, :tracer) do
      :tracer -> TracerStore
      :dets -> DetsStore
      other -> raise "Unknown storage backend: #{inspect(other)}"
    end
  end
end
