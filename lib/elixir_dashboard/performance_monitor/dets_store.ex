defmodule ElixirDashboard.PerformanceMonitor.DetsStore do
  @moduledoc """
  DETS-based persistent storage for performance monitoring data.

  Stores slow endpoints and queries in DETS tables for persistence across restarts.
  Automatically prunes old entries to maintain a maximum number of items.
  """
  use GenServer
  require Logger

  @default_max_items 100
  @dets_dir "priv/dets"
  @endpoints_table :elixir_dashboard_endpoints
  @queries_table :elixir_dashboard_queries

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
    # Ensure DETS directory exists
    File.mkdir_p!(@dets_dir)

    # Open DETS tables
    endpoints_file = Path.join(@dets_dir, "endpoints.dets") |> String.to_charlist()
    queries_file = Path.join(@dets_dir, "queries.dets") |> String.to_charlist()

    {:ok, endpoints_table} = :dets.open_file(@endpoints_table, file: endpoints_file, type: :set)
    {:ok, queries_table} = :dets.open_file(@queries_table, file: queries_file, type: :set)

    Logger.info("DETS storage initialized: #{@dets_dir}")

    {:ok, %{endpoints: endpoints_table, queries: queries_table}}
  end

  @impl true
  def handle_cast({:add_slow_endpoint, data}, state) do
    # Add timestamp-based key
    key = {data.timestamp, :rand.uniform(1_000_000)}
    :dets.insert(state.endpoints, {key, data})

    # Prune old entries
    prune_table(state.endpoints, max_items())

    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_slow_query, data}, state) do
    # Add timestamp-based key
    key = {data.timestamp, :rand.uniform(1_000_000)}
    :dets.insert(state.queries, {key, data})

    # Prune old entries
    prune_table(state.queries, max_items())

    {:noreply, state}
  end

  @impl true
  def handle_cast(:clear_all, state) do
    :dets.delete_all_objects(state.endpoints)
    :dets.delete_all_objects(state.queries)
    Logger.info("Cleared all DETS data")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_slow_endpoints, _from, state) do
    endpoints =
      state.endpoints
      |> :dets.match({:"$1", :"$2"})
      |> Enum.map(fn [_key, data] -> data end)
      |> Enum.sort_by(& &1.duration_ms, :desc)
      |> Enum.take(max_items())

    {:reply, endpoints, state}
  end

  @impl true
  def handle_call(:get_slow_queries, _from, state) do
    queries =
      state.queries
      |> :dets.match({:"$1", :"$2"})
      |> Enum.map(fn [_key, data] -> data end)
      |> Enum.sort_by(& &1.duration_ms, :desc)
      |> Enum.take(max_items())

    {:reply, queries, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    endpoints_count = :dets.info(state.endpoints, :size)
    queries_count = :dets.info(state.queries, :size)

    stats = %{
      endpoints_count: endpoints_count,
      queries_count: queries_count,
      max_items: max_items(),
      storage_type: "DETS",
      storage_path: @dets_dir
    }

    {:reply, stats, state}
  end

  @impl true
  def terminate(_reason, state) do
    :dets.close(state.endpoints)
    :dets.close(state.queries)
    :ok
  end

  # Private Functions

  defp max_items do
    Application.get_env(:elixir_dashboard, :max_items, @default_max_items)
  end

  defp prune_table(table, max) do
    size = :dets.info(table, :size)

    if size > max do
      # Get all entries sorted by duration (slowest first)
      all_entries =
        table
        |> :dets.match({:"$1", :"$2"})
        |> Enum.map(fn [key, data] -> {key, data} end)
        |> Enum.sort_by(fn {_key, data} -> data.duration_ms end, :desc)

      # Keep only the slowest max entries
      {_to_keep, to_delete} = Enum.split(all_entries, max)

      # Delete the slower entries
      Enum.each(to_delete, fn {key, _data} ->
        :dets.delete(table, key)
      end)

      Logger.debug("Pruned #{length(to_delete)} entries from DETS table")
    end
  end
end
