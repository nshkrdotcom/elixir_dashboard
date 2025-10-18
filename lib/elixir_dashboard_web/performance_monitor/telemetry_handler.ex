defmodule ElixirDashboardWeb.PerformanceMonitor.TelemetryHandler do
  @moduledoc """
  Backwards compatibility alias for the demo app.
  Real implementations should use ElixirDashboard.PerformanceMonitor.TelemetryHandler directly.
  """
  defdelegate attach(), to: ElixirDashboard.PerformanceMonitor.TelemetryHandler
  defdelegate detach(), to: ElixirDashboard.PerformanceMonitor.TelemetryHandler
end
