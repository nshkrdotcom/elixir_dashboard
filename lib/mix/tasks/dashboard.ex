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
    Mix.Task.run("app.start")

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
    Mix.Task.run("app.start")

    ElixirDashboard.PerformanceMonitor.Store.clear_all()
    IO.puts(IO.ANSI.green() <> "✓ Dashboard data cleared" <> IO.ANSI.reset())
  end
end

defmodule Mix.Tasks.Dashboard.Test do
  @moduledoc """
  Generate test data by hitting slow endpoints.

  ## Usage

      mix dashboard.test [count]

  Defaults to 10 requests if count not specified.
  """
  @shortdoc "Generate test slow endpoints/queries"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    count =
      case args do
        [n] -> String.to_integer(n)
        _ -> 10
      end

    IO.puts(IO.ANSI.cyan() <> "\n Generating #{count} test requests..." <> IO.ANSI.reset())

    endpoints = [
      "/demo/slow_cpu?ms=150",
      "/demo/slow_query?seconds=0.1",
      "/demo/complex_query",
      "/demo/multiple_queries",
      "/demo/random_slow"
    ]

    for i <- 1..count do
      endpoint = Enum.random(endpoints)
      url = "http://localhost:4000#{endpoint}"

      case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
        {:ok, {{_, 200, _}, _, _}} ->
          IO.write(IO.ANSI.green() <> "." <> IO.ANSI.reset())

        {:error, reason} ->
          IO.puts(
            IO.ANSI.red() <> "\n✗ Error on request #{i}: #{inspect(reason)}" <> IO.ANSI.reset()
          )
      end

      Process.sleep(100)
    end

    IO.puts(IO.ANSI.green() <> "\n✓ Generated #{count} test requests" <> IO.ANSI.reset())
    IO.puts("\nRun `mix dashboard.stats` to see results")
  end
end
