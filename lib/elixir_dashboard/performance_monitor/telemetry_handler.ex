defmodule ElixirDashboard.PerformanceMonitor.TelemetryHandler do
  @moduledoc """
  Attaches to Phoenix and Ecto telemetry events to capture performance metrics.

  ## Configuration

  You can configure the thresholds for what gets captured:

      config :elixir_dashboard,
        endpoint_threshold_ms: 100,
        query_threshold_ms: 50,
        repo_prefixes: [[:my_app, :repo]]

  ## Usage

  In your application.ex:

      if Mix.env() == :dev do
        ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
      end
  """

  alias ElixirDashboard.PerformanceMonitor.Store

  @default_endpoint_threshold 100
  @default_query_threshold 50

  defp endpoint_threshold do
    Application.get_env(:elixir_dashboard, :endpoint_threshold_ms, @default_endpoint_threshold)
  end

  defp query_threshold do
    Application.get_env(:elixir_dashboard, :query_threshold_ms, @default_query_threshold)
  end

  defp repo_prefixes do
    Application.get_env(:elixir_dashboard, :repo_prefixes, [])
  end

  @doc """
  Attaches telemetry handlers for Phoenix and Ecto events.
  """
  def attach do
    # Events from Phoenix/Plug
    :telemetry.attach(
      "elixir-dashboard-phoenix-stop",
      [:phoenix, :endpoint, :stop],
      &__MODULE__.handle_phoenix_event/4,
      nil
    )

    # Events from Ecto - use configured repo prefixes
    if repo_prefixes() != [] do
      events = Enum.map(repo_prefixes(), fn prefix -> prefix ++ [:query] end)

      :telemetry.attach_many(
        "elixir-dashboard-ecto-query",
        events,
        &__MODULE__.handle_ecto_event/4,
        nil
      )
    end
  end

  @doc """
  Detaches all telemetry handlers.
  """
  def detach do
    :telemetry.detach("elixir-dashboard-phoenix-stop")

    if repo_prefixes() != [] do
      :telemetry.detach("elixir-dashboard-ecto-query")
    end
  end

  # --- Event Handlers ---

  @doc false
  def handle_phoenix_event([:phoenix, :endpoint, :stop], measurements, metadata, _config) do
    # Store the endpoint path in the process dictionary for Ecto events to find
    # This is a simple way to correlate events within the same request process.
    conn = metadata.conn
    full_path = "#{conn.method} #{conn.request_path}"
    Process.put(:elixir_dashboard_request_path, full_path)

    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    # Only store endpoints that are slower than threshold
    if duration_ms > endpoint_threshold() do
      Store.add_slow_endpoint(%{
        path: full_path,
        duration_ms: duration_ms,
        timestamp: :os.system_time(:millisecond)
      })
    end
  end

  @doc false
  def handle_ecto_event([_app | _], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.total_time, :native, :millisecond)

    # Only store queries that are slower than threshold
    if duration_ms > query_threshold() do
      Store.add_slow_query(%{
        query: metadata.query,
        params: metadata.params || [],
        duration_ms: duration_ms,
        endpoint_path: Process.get(:elixir_dashboard_request_path, "N/A (Background Process)"),
        timestamp: :os.system_time(:millisecond)
      })
    end
  end
end
