defmodule ElixirDashboardWeb.DemoController do
  @moduledoc """
  Demo controller with intentionally slow endpoints for testing the dashboard.
  """
  use ElixirDashboardWeb, :controller
  import Ecto.Query
  alias ElixirDashboardWeb.Repo

  @doc """
  Slow endpoint using Process.sleep - simulates CPU-bound work
  """
  def slow_cpu(conn, params) do
    sleep_ms = String.to_integer(params["ms"] || "150")
    Process.sleep(sleep_ms)

    json(conn, %{
      message: "Slept for #{sleep_ms}ms",
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Slow database query using pg_sleep
  """
  def slow_query(conn, params) do
    sleep_seconds = String.to_float(params["seconds"] || "0.1")

    # Use pg_sleep to simulate a slow query
    Repo.query!("SELECT pg_sleep($1)", [sleep_seconds])

    # Also fetch some data
    users = Repo.all(from(u in "demo_users", limit: 10))

    json(conn, %{
      message: "Query slept for #{sleep_seconds}s",
      users_count: length(users),
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Complex slow query with joins and aggregations
  """
  def complex_query(conn, _params) do
    # Simulate a complex slow query
    result =
      Repo.query!("""
      SELECT
        u.name,
        u.email,
        COUNT(p.id) as post_count,
        pg_sleep(0.08) -- 80ms delay
      FROM demo_users u
      LEFT JOIN demo_posts p ON p.user_id = u.id
      WHERE u.age > 25
      GROUP BY u.id, u.name, u.email
      HAVING COUNT(p.id) > 3
      ORDER BY post_count DESC
      LIMIT 20
      """)

    json(conn, %{
      message: "Complex query completed",
      results_count: length(result.rows),
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Multiple queries - shows query correlation
  """
  def multiple_queries(conn, _params) do
    # Several queries that will all be tracked
    Repo.query!("SELECT pg_sleep(0.06)", [])
    users = Repo.all(from(u in "demo_users", limit: 5))

    Repo.query!("SELECT pg_sleep(0.07)", [])
    posts = Repo.all(from(p in "demo_posts", limit: 10))

    Repo.query!("SELECT pg_sleep(0.08)", [])

    json(conn, %{
      message: "Multiple queries completed",
      users_count: length(users),
      posts_count: length(posts),
      timestamp: DateTime.utc_now()
    })
  end

  @doc """
  Generate random slow traffic for testing
  """
  def random_slow(conn, _params) do
    # Random delay between 100-500ms
    delay = :rand.uniform(400) + 100
    Process.sleep(delay)

    # Random query delay
    query_delay = :rand.uniform(200) / 1000.0
    Repo.query!("SELECT pg_sleep($1)", [query_delay])

    json(conn, %{
      message: "Random slow endpoint",
      cpu_delay_ms: delay,
      query_delay_s: query_delay,
      timestamp: DateTime.utc_now()
    })
  end
end
