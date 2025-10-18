defmodule Mix.Tasks.Dashboard.Stats do
  @moduledoc """
  Show current dashboard statistics.

  ## Usage

      mix dashboard.stats
  """
  @shortdoc "Show dashboard statistics"

  use Mix.Task
  require Logger

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start", [])

    stats = ElixirDashboard.PerformanceMonitor.Store.get_stats()
    endpoints = ElixirDashboard.PerformanceMonitor.Store.get_slow_endpoints()
    queries = ElixirDashboard.PerformanceMonitor.Store.get_slow_queries()

    IO.puts("\n" <> IO.ANSI.cyan() <> "=== ElixirDashboard Statistics ===" <> IO.ANSI.reset())
    IO.puts("")
    IO.puts("Storage Type:    #{stats.storage_type}")
    IO.puts("Storage Path:    #{stats.storage_path}")
    IO.puts("Max Items:       #{stats.max_items}")
    IO.puts("")

    IO.puts(
      IO.ANSI.yellow() <> "Endpoints:       #{stats.endpoints_count} recorded" <> IO.ANSI.reset()
    )

    IO.puts(
      IO.ANSI.yellow() <> "Queries:         #{stats.queries_count} recorded" <> IO.ANSI.reset()
    )

    IO.puts("")

    if length(endpoints) > 0 do
      IO.puts(IO.ANSI.green() <> "Top 5 Slowest Endpoints:" <> IO.ANSI.reset())

      endpoints
      |> Enum.take(5)
      |> Enum.each(fn ep ->
        IO.puts("  #{ep.duration_ms}ms - #{ep.path}")
      end)

      IO.puts("")
    end

    if length(queries) > 0 do
      IO.puts(IO.ANSI.green() <> "Top 5 Slowest Queries:" <> IO.ANSI.reset())

      queries
      |> Enum.take(5)
      |> Enum.each(fn q ->
        query_preview = String.slice(q.query, 0..60)
        IO.puts("  #{q.duration_ms}ms - #{query_preview}...")
      end)

      IO.puts("")
    end

    :ok
  end
end

defmodule Mix.Tasks.Dashboard.Clear do
  @moduledoc """
  Clear all dashboard data.

  ## Usage

      mix dashboard.clear
  """
  @shortdoc "Clear all dashboard data"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start", [])

    ElixirDashboard.PerformanceMonitor.Store.clear_all()
    IO.puts(IO.ANSI.green() <> "✓ Dashboard data cleared" <> IO.ANSI.reset())
  end
end

defmodule Mix.Tasks.Dashboard.SlowQuery do
  @moduledoc """
  Execute a slow database query using pg_sleep.

  ## Usage

      mix dashboard.slow_query [seconds]

  Defaults to 0.15 seconds if not specified.
  """
  @shortdoc "Execute a slow database query"

  use Mix.Task
  alias ElixirDashboardWeb.Repo

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    seconds =
      case args do
        [s] -> String.to_float(s)
        _ -> 0.15
      end

    IO.puts(
      IO.ANSI.cyan() <> "\n🐘 Executing slow query (pg_sleep #{seconds}s)..." <> IO.ANSI.reset()
    )

    # Execute slow query
    Repo.query!("SELECT pg_sleep($1)", [seconds])

    # Also run a real query
    result = Repo.query!("SELECT COUNT(*) FROM demo_users")
    [[count]] = result.rows

    IO.puts(IO.ANSI.green() <> "✓ Query completed" <> IO.ANSI.reset())
    IO.puts("  Found #{count} users in database")
    IO.puts("\nCheck /dev/performance/queries to see it tracked")
  end
end

defmodule Mix.Tasks.Dashboard.SlowEndpoint do
  @moduledoc """
  Simulate a slow endpoint using Process.sleep.

  ## Usage

      mix dashboard.slow_endpoint [milliseconds]

  Defaults to 200ms if not specified.
  """
  @shortdoc "Simulate a slow endpoint"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    ms =
      case args do
        [m] -> String.to_integer(m)
        _ -> 200
      end

    IO.puts(IO.ANSI.cyan() <> "\n⏱️  Simulating slow endpoint (#{ms}ms)..." <> IO.ANSI.reset())

    # Simulate endpoint work
    Process.sleep(ms)

    IO.puts(IO.ANSI.green() <> "✓ Completed after #{ms}ms" <> IO.ANSI.reset())
    IO.puts("\nNote: This simulates the work but doesn't create an HTTP request.")
    IO.puts("To track in dashboard, use: mix dashboard.test")
  end
end

defmodule Mix.Tasks.Dashboard.Test do
  @moduledoc """
  Generate test data by calling demo endpoints via HTTP.

  ## Usage

      mix dashboard.test [count]

  Defaults to 10 requests if count not specified.

  Note: Server must be running! Start with `./start.sh` first.
  """
  @shortdoc "Generate test slow endpoints/queries (requires running server)"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Don't start the app - we'll call the running server via HTTP
    :inets.start()

    count =
      case args do
        [n] -> String.to_integer(n)
        _ -> 10
      end

    IO.puts(
      IO.ANSI.cyan() <>
        "\n🚀 Generating #{count} test requests to http://localhost:4000..." <> IO.ANSI.reset()
    )

    IO.puts("   (Make sure server is running with ./start.sh)\n")

    endpoints = [
      "/demo/slow_cpu?ms=150",
      "/demo/slow_query?seconds=0.1",
      "/demo/complex_query",
      "/demo/multiple_queries",
      "/demo/random_slow"
    ]

    for _i <- 1..count do
      endpoint = Enum.random(endpoints)
      url = "http://localhost:4000#{endpoint}"

      case :httpc.request(:get, {String.to_charlist(url), []}, [{:timeout, 5000}], []) do
        {:ok, {{_, 200, _}, _, _}} ->
          IO.write(IO.ANSI.green() <> "." <> IO.ANSI.reset())

        {:error, :econnrefused} ->
          IO.puts(
            IO.ANSI.red() <>
              "\n✗ Server not running! Start with ./start.sh first" <> IO.ANSI.reset()
          )

          System.halt(1)

        {:error, reason} ->
          IO.puts(IO.ANSI.yellow() <> "\n⚠ #{inspect(reason)}" <> IO.ANSI.reset())
      end

      Process.sleep(100)
    end

    IO.puts(IO.ANSI.green() <> "\n✓ Generated #{count} test requests" <> IO.ANSI.reset())
    IO.puts("\nRefresh browser to see results:")
    IO.puts("  http://localhost:4000/dev/performance/endpoints")
    IO.puts("  http://localhost:4000/dev/performance/queries")
  end
end

defmodule Mix.Tasks.Dashboard.Fixtures do
  @moduledoc """
  Generate fixture data for all ElixirTracer dashboards.

  ## Usage

      # Generate all fixtures with defaults
      mix dashboard.fixtures

      # Generate with custom counts
      mix dashboard.fixtures --errors 10 --events 20

  ## Options

    * `--errors` - Number of error traces to generate (default: 5)
    * `--events` - Number of custom events to generate (default: 10)
    * Metrics are always generated comprehensively

  This will populate:
    - Errors dashboard with realistic exception traces
    - Metrics dashboard with database and external service metrics
    - Events dashboard with business events (signups, purchases, etc.)
  """
  @shortdoc "Generate fixture data for errors, metrics, and events"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start", [])

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [errors: :integer, events: :integer],
        aliases: [e: :errors, v: :events]
      )

    error_count = Keyword.get(opts, :errors, 5)
    event_count = Keyword.get(opts, :events, 10)

    IO.puts(IO.ANSI.cyan() <> "\n📊 Generating fixture data..." <> IO.ANSI.reset())
    IO.puts("")

    # Generate errors
    IO.puts(IO.ANSI.yellow() <> "Generating #{error_count} error traces..." <> IO.ANSI.reset())
    ElixirDashboard.Fixtures.generate_errors(error_count)
    IO.puts(IO.ANSI.green() <> "  ✓ #{error_count} errors generated" <> IO.ANSI.reset())

    # Generate metrics
    IO.puts(IO.ANSI.yellow() <> "\nGenerating performance metrics..." <> IO.ANSI.reset())
    ElixirDashboard.Fixtures.generate_metrics()
    IO.puts(IO.ANSI.green() <> "  ✓ Database metrics generated" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "  ✓ External service metrics generated" <> IO.ANSI.reset())
    IO.puts(IO.ANSI.green() <> "  ✓ Custom metrics generated" <> IO.ANSI.reset())

    # Generate events
    IO.puts(IO.ANSI.yellow() <> "\nGenerating #{event_count} custom events..." <> IO.ANSI.reset())
    ElixirDashboard.Fixtures.generate_events(event_count)
    IO.puts(IO.ANSI.green() <> "  ✓ #{event_count} events generated" <> IO.ANSI.reset())

    IO.puts(IO.ANSI.cyan() <> "\n✨ Fixture generation complete!" <> IO.ANSI.reset())
    IO.puts("\nView the data in your dashboards:")
    IO.puts("  http://localhost:4000/dev/performance/errors")
    IO.puts("  http://localhost:4000/dev/performance/metrics")
    IO.puts("  http://localhost:4000/dev/performance/events")
  end
end
