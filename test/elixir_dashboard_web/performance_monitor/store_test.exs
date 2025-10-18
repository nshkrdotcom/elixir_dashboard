defmodule ElixirDashboardWeb.PerformanceMonitor.StoreTest do
  use ExUnit.Case, async: false

  alias ElixirDashboardWeb.PerformanceMonitor.Store

  setup do
    # Configure to use DETS backend for these tests
    Application.put_env(:elixir_dashboard, :storage_backend, :dets)

    # Start the DetsStore GenServer if not already started
    case GenServer.whereis(ElixirDashboard.PerformanceMonitor.DetsStore) do
      nil ->
        {:ok, _pid} = ElixirDashboard.PerformanceMonitor.DetsStore.start_link([])

      _pid ->
        :ok
    end

    # Give the GenServer a moment to initialize DETS tables
    Process.sleep(50)

    # Clear store before each test
    Store.clear_all()

    # Give the cast a moment to process
    Process.sleep(50)

    on_exit(fn ->
      # Reset to default backend
      Application.put_env(:elixir_dashboard, :storage_backend, :tracer)
    end)

    :ok
  end

  test "stores slow endpoints" do
    endpoint_data = %{
      path: "GET /api/test",
      duration_ms: 250,
      timestamp: :os.system_time(:millisecond)
    }

    Store.add_slow_endpoint(endpoint_data)
    # Give the cast a moment to process
    Process.sleep(50)
    endpoints = Store.get_slow_endpoints()

    assert length(endpoints) == 1
    assert hd(endpoints).path == "GET /api/test"
    assert hd(endpoints).duration_ms == 250
  end

  test "stores slow queries" do
    query_data = %{
      query: "SELECT * FROM users",
      params: [],
      duration_ms: 100,
      endpoint_path: "GET /users",
      timestamp: :os.system_time(:millisecond)
    }

    Store.add_slow_query(query_data)
    # Give the cast a moment to process
    Process.sleep(50)
    queries = Store.get_slow_queries()

    assert length(queries) == 1
    assert hd(queries).query == "SELECT * FROM users"
    assert hd(queries).duration_ms == 100
  end

  test "clears all data" do
    Store.add_slow_endpoint(%{
      path: "GET /test",
      duration_ms: 200,
      timestamp: :os.system_time(:millisecond)
    })

    Store.clear_all()

    assert Store.get_slow_endpoints() == []
    assert Store.get_slow_queries() == []
  end
end
