defmodule ElixirDashboard.PerformanceMonitor.Supervisor do
  @moduledoc """
  Supervisor for the Performance Monitor components.

  Add this to your application supervision tree:

      children = [
        # ... your other children
        ElixirDashboard.PerformanceMonitor.Supervisor
      ]
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Start the configured storage backend (TracerStore or DetsStore)
      ElixirDashboard.PerformanceMonitor.Store
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
