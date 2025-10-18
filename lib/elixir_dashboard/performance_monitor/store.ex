defmodule ElixirDashboard.PerformanceMonitor.Store do
  @moduledoc """
  Storage facade that delegates to DETS-based persistent storage.

  In dev/test: Uses DETS for persistence (data survives restarts)
  In prod: Uses in-memory storage (ephemeral)

  Configuration:

      config :elixir_dashboard, :max_items, 100
  """

  alias ElixirDashboard.PerformanceMonitor.DetsStore

  # Client API - delegates to DETS
  def start_link(opts) do
    DetsStore.start_link(opts)
  end

  def add_slow_endpoint(endpoint_data) do
    DetsStore.add_slow_endpoint(endpoint_data)
  end

  def add_slow_query(query_data) do
    DetsStore.add_slow_query(query_data)
  end

  def get_slow_endpoints do
    DetsStore.get_slow_endpoints()
  end

  def get_slow_queries do
    DetsStore.get_slow_queries()
  end

  def clear_all do
    DetsStore.clear_all()
  end

  def get_stats do
    DetsStore.get_stats()
  end
end
