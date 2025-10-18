defmodule ElixirDashboard.PerformanceMonitor.Store do
  @moduledoc """
  GenServer that stores performance monitoring data in memory.

  Maintains two sorted lists:
  - Slow endpoints (top N slowest API requests)
  - Slow queries (top N slowest database queries)

  The size of each list is configurable via application config:

      config :elixir_dashboard, :max_items, 100
  """
  use GenServer

  @default_max_items 100

  defp max_items do
    Application.get_env(:elixir_dashboard, :max_items, @default_max_items)
  end

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{endpoints: [], queries: []}, name: __MODULE__)
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

  # Server Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_slow_endpoint, data}, state) do
    new_endpoints =
      (state.endpoints ++ [data])
      |> Enum.sort_by(& &1.duration_ms, :desc)
      |> Enum.take(max_items())

    {:noreply, %{state | endpoints: new_endpoints}}
  end

  @impl true
  def handle_cast({:add_slow_query, data}, state) do
    new_queries =
      (state.queries ++ [data])
      |> Enum.sort_by(& &1.duration_ms, :desc)
      |> Enum.take(max_items())

    {:noreply, %{state | queries: new_queries}}
  end

  @impl true
  def handle_cast(:clear_all, _state) do
    {:noreply, %{endpoints: [], queries: []}}
  end

  @impl true
  def handle_call(:get_slow_endpoints, _from, state) do
    {:reply, state.endpoints, state}
  end

  @impl true
  def handle_call(:get_slow_queries, _from, state) do
    {:reply, state.queries, state}
  end
end
