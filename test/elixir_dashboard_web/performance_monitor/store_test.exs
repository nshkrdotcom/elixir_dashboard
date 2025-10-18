defmodule ElixirDashboardWeb.PerformanceMonitor.StoreTest do
  use ExUnit.Case, async: false

  alias ElixirDashboardWeb.PerformanceMonitor.Store

  setup do
    # Clear store before each test
    Store.clear_all()
    :ok
  end

  test "stores slow endpoints" do
    endpoint_data = %{
      path: "GET /api/test",
      duration_ms: 250,
      timestamp: :os.system_time(:millisecond)
    }

    Store.add_slow_endpoint(endpoint_data)
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
