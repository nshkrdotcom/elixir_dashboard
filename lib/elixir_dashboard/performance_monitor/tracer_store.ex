defmodule ElixirDashboard.PerformanceMonitor.TracerStore do
  @moduledoc """
  Storage adapter using ElixirTracer's comprehensive observability backend.

  This module provides a backward-compatible API that maps ElixirDashboard's
  simple endpoint/query model to ElixirTracer's rich transaction/span model.

  ## Mapping

  - **Endpoints** → ElixirTracer transactions (filtered by type :web)
  - **Queries** → ElixirTracer spans (filtered by category :datastore)

  ## Benefits

  - Unified storage with ElixirTracer
  - Access to rich transaction details
  - Distributed tracing support
  - Error correlation
  - Metrics aggregation
  """
  use GenServer
  require Logger

  @default_max_items 100

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_slow_endpoint(endpoint_data) do
    GenServer.cast(__MODULE__, {:add_slow_endpoint, endpoint_data})
  end

  def add_slow_query(query_data) do
    GenServer.cast(__MODULE__, {:add_slow_query, query_data})
  end

  def get_slow_endpoints do
    GenServer.call(__MODULE__, :get_slow_endpoints)
  end

  def get_slow_queries do
    GenServer.call(__MODULE__, :get_slow_queries)
  end

  def clear_all do
    GenServer.cast(__MODULE__, :clear_all)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("TracerStore initialized - using ElixirTracer backend")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add_slow_endpoint, endpoint_data}, state) do
    # This is called by legacy telemetry handler
    # Data is now captured by ElixirTracer's handlers
    # We keep this for backward compatibility but it's a no-op
    # since ElixirTracer.Telemetry.PlugHandler already creates transactions
    Logger.debug(
      "Legacy endpoint data received (handled by ElixirTracer): #{inspect(endpoint_data)}"
    )

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_slow_query, query_data}, state) do
    # This is called by legacy telemetry handler
    # Data is now captured by ElixirTracer's handlers
    Logger.debug("Legacy query data received (handled by ElixirTracer): #{inspect(query_data)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:clear_all, state) do
    ElixirTracer.Query.clear_all()
    Logger.info("Cleared all ElixirTracer data")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_slow_endpoints, _from, state) do
    endpoints = fetch_slow_endpoints()
    {:reply, endpoints, state}
  end

  @impl true
  def handle_call(:get_slow_queries, _from, state) do
    queries = fetch_slow_queries()
    {:reply, queries, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    tracer_stats = ElixirTracer.Query.get_stats()

    # Map ElixirTracer stats to dashboard format
    stats = %{
      endpoints_count: tracer_stats.transactions,
      queries_count: tracer_stats.spans,
      errors_count: tracer_stats.errors,
      metrics_count: tracer_stats.metrics,
      events_count: tracer_stats.custom_events,
      max_items: max_items(),
      storage_type: "ElixirTracer (DETS)",
      storage_path: tracer_stats.storage_path
    }

    {:reply, stats, state}
  end

  # Private Functions

  defp fetch_slow_endpoints do
    threshold_ms = endpoint_threshold()
    max = max_items()

    # Get all web transactions from ElixirTracer
    transactions =
      ElixirTracer.Query.get_transactions(
        type: :web,
        sort: :duration_desc,
        # Get more than needed to filter
        limit: max * 2
      )

    # Filter by threshold and convert to dashboard format
    transactions
    |> Enum.filter(fn tx -> tx.duration_ms >= threshold_ms end)
    |> Enum.take(max)
    |> Enum.map(&transaction_to_endpoint/1)
  end

  defp fetch_slow_queries do
    threshold_ms = query_threshold()
    max = max_items()

    # Get all datastore spans from ElixirTracer
    spans =
      ElixirTracer.Query.get_spans(
        sort: :duration_desc,
        # Get more since we'll filter heavily
        limit: max * 5
      )

    # Filter datastore spans by threshold and convert to dashboard format
    spans
    |> Enum.filter(fn span ->
      span.category == :datastore && span.duration_s * 1000 >= threshold_ms
    end)
    |> Enum.take(max)
    |> Enum.map(&span_to_query/1)
  end

  defp transaction_to_endpoint(tx) do
    %{
      path: tx.name,
      duration_ms: tx.duration_ms,
      # ElixirTracer uses start_time not start_time_ms
      timestamp: tx.start_time,
      # Enhanced fields from ElixirTracer
      transaction_id: tx.id,
      trace_id: tx.trace_id,
      status: tx.status,
      custom_attributes: tx.custom_attributes,
      error_count: count_transaction_errors(tx.id)
    }
  end

  defp span_to_query(span) do
    # Extract query details from span attributes
    db_statement = get_in(span.attributes, ["db.statement"]) || "N/A"
    db_table = get_in(span.attributes, ["db.table"]) || "unknown"
    db_operation = get_in(span.attributes, ["db.operation"]) || "SELECT"

    # Try to find the associated transaction name
    endpoint_path = get_endpoint_path_for_span(span)

    %{
      query: db_statement,
      # ElixirTracer doesn't store params by default
      params: [],
      duration_ms: round(span.duration_s * 1000),
      endpoint_path: endpoint_path,
      timestamp: span.timestamp,
      # Enhanced fields from ElixirTracer
      span_id: span.id,
      transaction_id: span.transaction_id,
      db_table: db_table,
      db_operation: db_operation,
      db_instance: get_in(span.attributes, ["db.instance"]),
      peer_hostname: get_in(span.attributes, ["peer.hostname"])
    }
  end

  defp get_endpoint_path_for_span(span) do
    # If span has a transaction_id, fetch the transaction name
    case span.transaction_id do
      nil ->
        "N/A (Background Process)"

      tx_id ->
        # Get all transactions and find the matching one
        transactions = ElixirTracer.Query.get_transactions()

        case Enum.find(transactions, fn tx -> tx.id == tx_id end) do
          nil -> "N/A (Transaction not found)"
          tx -> tx.name
        end
    end
  end

  defp count_transaction_errors(transaction_id) do
    # Get all errors and count those associated with this transaction
    errors = ElixirTracer.Query.get_errors()
    Enum.count(errors, fn error -> error.transaction_id == transaction_id end)
  end

  defp endpoint_threshold do
    Application.get_env(:elixir_dashboard, :endpoint_threshold_ms, 100)
  end

  defp query_threshold do
    Application.get_env(:elixir_dashboard, :query_threshold_ms, 50)
  end

  defp max_items do
    Application.get_env(:elixir_dashboard, :max_items, @default_max_items)
  end
end
