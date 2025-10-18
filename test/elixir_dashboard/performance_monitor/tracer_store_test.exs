defmodule ElixirDashboard.PerformanceMonitor.TracerStoreTest do
  use ElixirDashboard.SupertesterCase, async: true

  alias ElixirDashboard.PerformanceMonitor.TracerStore

  # Setup handled by SupertesterCase (clears ElixirTracer data)

  describe "get_slow_endpoints/0" do
    test "returns empty list when no transactions exist" do
      assert TracerStore.get_slow_endpoints() == []
    end

    test "returns web transactions above threshold" do
      # Create a web transaction using ElixirTracer
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /slow-endpoint")
      # Simulate slow request
      Process.sleep(150)
      {:ok, _tx} = ElixirTracer.Transaction.Reporter.stop_transaction()

      # Use deterministic polling instead of assuming immediate availability
      wait_for_transactions(fn txs -> length(txs) == 1 end, timeout: 2000)

      endpoints = TracerStore.get_slow_endpoints()
      assert length(endpoints) == 1

      [endpoint] = endpoints
      assert endpoint.path == "GET /slow-endpoint"
      assert endpoint.duration_ms >= 100
      assert is_integer(endpoint.timestamp)
    end

    test "filters out transactions below threshold" do
      # Fast transaction (below 100ms threshold)
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /fast")
      Process.sleep(10)
      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Slow transaction (above threshold)
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /slow")
      Process.sleep(150)
      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for transactions to be stored
      wait_for_transactions(fn txs -> length(txs) >= 2 end, timeout: 2000)

      # TracerStore should filter and return only the slow one
      endpoints = TracerStore.get_slow_endpoints()
      assert length(endpoints) == 1
      [endpoint] = endpoints
      assert String.contains?(endpoint.path, "/slow")
    end

    test "includes enhanced fields from ElixirTracer" do
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /test")
      ElixirTracer.Transaction.Reporter.add_attributes(user_id: 123, plan: "premium")
      Process.sleep(150)
      {:ok, _tx} = ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for transaction to be available
      wait_for_transactions(fn txs -> length(txs) > 0 end)

      [endpoint] = TracerStore.get_slow_endpoints()
      assert endpoint.transaction_id
      assert endpoint.trace_id
      assert endpoint.status == :completed
      assert endpoint.custom_attributes[:user_id] == 123
      assert endpoint.custom_attributes[:plan] == "premium"
    end
  end

  describe "get_slow_queries/0" do
    test "returns empty list when no spans exist" do
      assert TracerStore.get_slow_queries() == []
    end

    test "returns datastore spans above threshold" do
      # Create a transaction with a slow query span
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /users")

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

      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for span to be stored
      wait_for_spans(fn spans -> length(spans) > 0 end)

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
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /test")

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

      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for spans to be stored
      wait_for_spans(fn spans -> length(spans) >= 2 end)

      # TracerStore should filter and return only the slow one
      queries = TracerStore.get_slow_queries()
      assert length(queries) == 1
      [query] = queries
      assert String.contains?(query.query, "orders")
    end

    test "only returns datastore category spans" do
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /test")

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

      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for spans to be stored
      wait_for_spans(fn spans -> length(spans) >= 2 end)

      # Only datastore category should be returned
      queries = TracerStore.get_slow_queries()
      assert length(queries) == 1
      [query] = queries
      assert query.db_operation
    end
  end

  describe "clear_all/0" do
    test "clears all ElixirTracer data" do
      # Create some data
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /test")
      Process.sleep(150)
      ElixirTracer.Transaction.Reporter.stop_transaction()

      # Wait for data to be stored
      wait_for_transactions(fn txs -> length(txs) > 0 end)

      # Verify data exists
      assert length(TracerStore.get_slow_endpoints()) > 0

      # Clear all
      TracerStore.clear_all()

      # Verify data is cleared (should be immediate)
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
      ElixirTracer.Transaction.Reporter.start_transaction(:web, "GET /test")

      ElixirTracer.Span.Reporter.report_span(
        name: "DB Query",
        category: :datastore,
        duration_s: 0.1
      )

      ElixirTracer.Transaction.Reporter.stop_transaction()

      stats = TracerStore.get_stats()
      assert stats.endpoints_count >= 1
      assert stats.queries_count >= 1
    end
  end
end
