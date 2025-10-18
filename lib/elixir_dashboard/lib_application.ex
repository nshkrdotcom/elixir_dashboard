defmodule ElixirDashboard.LibApplication do
  @moduledoc """
  Minimal application module when ElixirDashboard is used as a library.

  This does NOT start a Phoenix endpoint - the library just provides
  the monitoring components that can be integrated into your host application.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # When used as a library, we don't start anything automatically.
    # The host application will start the components they need.
    children = []

    opts = [strategy: :one_for_one, name: ElixirDashboard.LibSupervisor]
    Supervisor.start_link(children, opts)
  end
end
