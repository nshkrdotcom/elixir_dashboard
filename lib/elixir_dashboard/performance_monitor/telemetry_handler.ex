defmodule ElixirDashboard.PerformanceMonitor.TelemetryHandler do
  @moduledoc """
  Enhanced telemetry handler using ElixirTracer's comprehensive instrumentation.

  This module integrates ElixirTracer's telemetry handlers while maintaining
  ElixirDashboard's threshold-based filtering for the UI display.

  ## Configuration

  You can configure the thresholds for what gets captured:

      config :elixir_dashboard,
        storage_backend: :tracer,  # Use ElixirTracer backend
        endpoint_threshold_ms: 100,
        query_threshold_ms: 50,
        repo_prefixes: [[:my_app, :repo]]

  ## Usage

  In your application.ex:

      if Mix.env() == :dev do
        ElixirDashboard.PerformanceMonitor.TelemetryHandler.attach()
      end

  ## How It Works

  1. ElixirTracer handlers automatically capture all telemetry events
  2. Dashboard handlers run in parallel to apply threshold filtering
  3. Dashboard UI queries ElixirTracer storage with threshold filters
  4. Result: Comprehensive data capture with selective display
  """

  require Logger

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

  defp use_tracer_backend? do
    Application.get_env(:elixir_dashboard, :storage_backend, :tracer) == :tracer
  end

  @doc """
  Attaches telemetry handlers for Phoenix and Ecto events.

  When using :tracer backend, this attaches ElixirTracer's comprehensive handlers.
  When using :dets backend, this uses legacy simple handlers.
  """
  def attach do
    if use_tracer_backend?() do
      attach_tracer_handlers()
    else
      attach_legacy_handlers()
    end
  end

  @doc """
  Detaches all telemetry handlers.
  """
  def detach do
    if use_tracer_backend?() do
      detach_tracer_handlers()
    else
      detach_legacy_handlers()
    end
  end

  # --- ElixirTracer Integration ---

  defp attach_tracer_handlers do
    Logger.info("Attaching ElixirTracer telemetry handlers for ElixirDashboard")

    # Attach ElixirTracer's comprehensive handlers
    ElixirTracer.Telemetry.PlugHandler.attach()
    ElixirTracer.Telemetry.PhoenixHandler.attach()

    # Attach Ecto handler with configured repo prefixes
    if repo_prefixes() != [] do
      ElixirTracer.Telemetry.EctoHandler.attach(repo_prefixes())
    end

    # Attach dashboard-specific handlers for enrichment
    :telemetry.attach(
      "elixir-dashboard-transaction-enrichment",
      [:phoenix, :endpoint, :stop],
      &__MODULE__.enrich_transaction/4,
      nil
    )

    Logger.info("ElixirTracer handlers attached successfully")
  end

  defp detach_tracer_handlers do
    # ElixirTracer doesn't provide detach functions, so we'll detach our enrichment handler
    :telemetry.detach("elixir-dashboard-transaction-enrichment")
  end

  @doc false
  def enrich_transaction([:phoenix, :endpoint, :stop], measurements, metadata, _config) do
    # Add dashboard-specific attributes to the current transaction
    conn = metadata.conn
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    # Mark slow requests for easy filtering
    if duration_ms >= endpoint_threshold() do
      ElixirTracer.Transaction.Reporter.add_attributes(
        dashboard_slow_endpoint: true,
        dashboard_threshold_ms: endpoint_threshold()
      )
    end

    # Add request metadata
    ElixirTracer.Transaction.Reporter.add_attributes(
      http_method: conn.method,
      http_path: conn.request_path,
      http_status: conn.status,
      dashboard_monitored: true
    )
  end

  # --- Legacy DETS Handlers ---

  defp attach_legacy_handlers do
    Logger.info("Attaching legacy DETS telemetry handlers")

    alias ElixirDashboard.PerformanceMonitor.Store

    # Events from Phoenix/Plug
    :telemetry.attach(
      "elixir-dashboard-phoenix-stop",
      [:phoenix, :endpoint, :stop],
      fn [:phoenix, :endpoint, :stop], measurements, metadata, _config ->
        # Store the endpoint path in the process dictionary for Ecto events to find
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
      end,
      nil
    )

    # Events from Ecto - use configured repo prefixes
    if repo_prefixes() != [] do
      events = Enum.map(repo_prefixes(), fn prefix -> prefix ++ [:query] end)

      :telemetry.attach_many(
        "elixir-dashboard-ecto-query",
        events,
        fn [_app | _], measurements, metadata, _config ->
          duration_ms = System.convert_time_unit(measurements.total_time, :native, :millisecond)

          # Only store queries that are slower than threshold
          if duration_ms > query_threshold() do
            Store.add_slow_query(%{
              query: metadata.query,
              params: metadata.params || [],
              duration_ms: duration_ms,
              endpoint_path:
                Process.get(:elixir_dashboard_request_path, "N/A (Background Process)"),
              timestamp: :os.system_time(:millisecond)
            })
          end
        end,
        nil
      )
    end
  end

  defp detach_legacy_handlers do
    :telemetry.detach("elixir-dashboard-phoenix-stop")

    if repo_prefixes() != [] do
      :telemetry.detach("elixir-dashboard-ecto-query")
    end
  end
end
