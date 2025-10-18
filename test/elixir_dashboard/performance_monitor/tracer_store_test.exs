defmodule ElixirDashboard.PerformanceMonitor.TracerStoreTest do
  use ExUnit.Case, async: false

  alias ElixirDashboard.PerformanceMonitor.TracerStore

  setup do
    # Clear all ElixirTracer data before each test
    ElixirTracer.Query.clear_all()
    :ok
  end

  describe "get_slow_endpoints/0" do
    test "returns empty list when no transactions exist" do
      assert TracerStore.get_slow_endpoints() == []
    end

    test "returns web transactions above threshold" do
      # Create a web transaction using ElixirTracer
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /slow-endpoint")
      # Simulate slow request
      Process.sleep(150)
      {:ok, _tx} = ElixirTracer.OtherTransaction.stop_transaction()

      endpoints = TracerStore.get_slow_endpoints()
      assert length(endpoints) == 1

      [endpoint] = endpoints
      assert endpoint.path == "OtherTransaction/GET /slow-endpoint"
      assert endpoint.duration_ms >= 100
      assert is_integer(endpoint.timestamp)
    end

    test "filters out transactions below threshold" do
      # Fast transaction (below 100ms threshold)
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /fast")
      Process.sleep(10)
      ElixirTracer.OtherTransaction.stop_transaction()

      # Slow transaction (above threshold)
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /slow")
      Process.sleep(150)
      ElixirTracer.OtherTransaction.stop_transaction()

      endpoints = TracerStore.get_slow_endpoints()
      assert length(endpoints) == 1
      [endpoint] = endpoints
      assert String.contains?(endpoint.path, "/slow")
    end

    test "includes enhanced fields from ElixirTracer" do
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /test")
      ElixirTracer.Transaction.Reporter.add_attributes(user_id: 123, plan: "premium")
      Process.sleep(150)
      {:ok, _tx} = ElixirTracer.OtherTransaction.stop_transaction()

      [endpoint] = TracerStore.get_slow_endpoints()
      assert endpoint.transaction_id
      assert endpoint.trace_id
      assert endpoint.status == :completed
      assert endpoint.custom_attributes == %{user_id: 123, plan: "premium"}
    end
  end

  describe "get_slow_queries/0" do
    test "returns empty list when no spans exist" do
      assert TracerStore.get_slow_queries() == []
    end

    test "returns datastore spans above threshold" do
      # Create a transaction with a slow query span
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /users")

      # Report a slow database span
      ElixirTracer.Span.Reporter.report_span(
        name: "Datastore/PostgreSQL/users/SELECT",
        category: :datastore,
        # 150ms - above 50ms threshold
        duration_s: 0.150,
        attributes: %{
          "db.statement" => "SELECT * FROM users WHERE id = $1",
          "db.table" => "users",
          "db.operation" => "SELECT",
          "db.instance" => "production_db"
        }
      )

      ElixirTracer.OtherTransaction.stop_transaction()

      queries = TracerStore.get_slow_queries()
      assert length(queries) == 1

      [query] = queries
      assert query.query == "SELECT * FROM users WHERE id = $1"
      assert query.duration_ms >= 50
      assert query.db_table == "users"
      assert query.db_operation == "SELECT"
      assert query.db_instance == "production_db"
    end

    test "filters out spans below threshold" do
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /test")

      # Fast query (below 50ms threshold)
      ElixirTracer.Span.Reporter.report_span(
        name: "Datastore/PostgreSQL/users/SELECT",
        category: :datastore,
        # 10ms
        duration_s: 0.010,
        attributes: %{"db.statement" => "SELECT * FROM users LIMIT 1"}
      )

      # Slow query (above threshold)
      ElixirTracer.Span.Reporter.report_span(
        name: "Datastore/PostgreSQL/orders/SELECT",
        category: :datastore,
        # 100ms
        duration_s: 0.100,
        attributes: %{"db.statement" => "SELECT * FROM orders"}
      )

      ElixirTracer.OtherTransaction.stop_transaction()

      queries = TracerStore.get_slow_queries()
      assert length(queries) == 1
      [query] = queries
      assert String.contains?(query.query, "orders")
    end

    test "only returns datastore category spans" do
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /test")

      # HTTP span (should be filtered out)
      ElixirTracer.Span.Reporter.report_span(
        name: "External/api.stripe.com/POST",
        category: :http,
        duration_s: 0.200,
        attributes: %{"http.url" => "https://api.stripe.com"}
      )

      # Database span (should be included)
      ElixirTracer.Span.Reporter.report_span(
        name: "Datastore/PostgreSQL/users/SELECT",
        category: :datastore,
        duration_s: 0.100,
        attributes: %{"db.statement" => "SELECT * FROM users"}
      )

      ElixirTracer.OtherTransaction.stop_transaction()

      queries = TracerStore.get_slow_queries()
      assert length(queries) == 1
      [query] = queries
      assert query.db_operation
    end
  end

  describe "clear_all/0" do
    test "clears all ElixirTracer data" do
      # Create some data
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /test")
      Process.sleep(150)
      ElixirTracer.OtherTransaction.stop_transaction()

      # Verify data exists
      assert length(TracerStore.get_slow_endpoints()) > 0

      # Clear all
      TracerStore.clear_all()

      # Verify data is cleared
      assert TracerStore.get_slow_endpoints() == []
      assert TracerStore.get_slow_queries() == []
    end
  end

  describe "get_stats/0" do
    test "returns statistics from ElixirTracer" do
      stats = TracerStore.get_stats()

      assert stats.endpoints_count >= 0
      assert stats.queries_count >= 0
      assert stats.errors_count >= 0
      assert stats.max_items == 100
      assert stats.storage_type == "ElixirTracer (DETS)"
      assert stats.storage_path
    end

    test "reflects current data counts" do
      # Create some transactions and spans
      ElixirTracer.OtherTransaction.start_transaction("WebTransaction", "GET /test")

      ElixirTracer.Span.Reporter.report_span(
        name: "DB Query",
        category: :datastore,
        duration_s: 0.1
      )

      ElixirTracer.OtherTransaction.stop_transaction()

      stats = TracerStore.get_stats()
      assert stats.endpoints_count >= 1
      assert stats.queries_count >= 1
    end
  end
end
