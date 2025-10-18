defmodule ElixirDashboardWeb.PerformanceMonitor.Supervisor do
  @moduledoc """
  Backwards compatibility alias for the demo app.
  Real implementations should use ElixirDashboard.PerformanceMonitor.Supervisor directly.
  """
  use Supervisor

  def start_link(init_arg) do
    # Delegate to the library supervisor
    ElixirDashboard.PerformanceMonitor.Supervisor.start_link(init_arg)
  end

  @impl true
  def init(init_arg) do
    ElixirDashboard.PerformanceMonitor.Supervisor.init(init_arg)
  end
end
