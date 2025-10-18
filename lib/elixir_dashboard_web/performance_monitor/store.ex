defmodule ElixirDashboardWeb.PerformanceMonitor.Store do
  @moduledoc """
  Backwards compatibility alias for the demo app.
  Real implementations should use ElixirDashboard.PerformanceMonitor.Store directly.
  """
  defdelegate start_link(opts), to: ElixirDashboard.PerformanceMonitor.Store
  defdelegate add_slow_endpoint(data), to: ElixirDashboard.PerformanceMonitor.Store
  defdelegate add_slow_query(data), to: ElixirDashboard.PerformanceMonitor.Store
  defdelegate get_slow_endpoints(), to: ElixirDashboard.PerformanceMonitor.Store
  defdelegate get_slow_queries(), to: ElixirDashboard.PerformanceMonitor.Store
  defdelegate clear_all(), to: ElixirDashboard.PerformanceMonitor.Store
end
