defmodule ElixirDashboard.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ElixirDashboardWeb.Telemetry,
        {DNSCluster,
         query: Application.get_env(:elixir_dashboard, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: ElixirDashboard.PubSub},
        # Start the Performance Monitor
        ElixirDashboardWeb.PerformanceMonitor.Supervisor
      ] ++
        repo_children() ++
        [
          # Start the Endpoint (http/https)
          ElixirDashboardWeb.Endpoint
        ]

    # Attach telemetry handlers only in dev
    if Application.get_env(:elixir_dashboard, :env) == :dev do
      ElixirDashboardWeb.PerformanceMonitor.TelemetryHandler.attach()
    end

    opts = [strategy: :one_for_one, name: ElixirDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Only start Repo in dev for demo purposes (not in test - tests don't need DB)
  defp repo_children do
    if Application.get_env(:elixir_dashboard, :env) == :dev do
      [ElixirDashboardWeb.Repo]
    else
      []
    end
  end
end
