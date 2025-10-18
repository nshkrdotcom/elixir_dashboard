defmodule ElixirDashboardWeb.Router do
  use ElixirDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirDashboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirDashboardWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Demo/testing endpoints (only in dev)
  if Mix.env() == :dev do
    scope "/demo", ElixirDashboardWeb do
      pipe_through :api

      get "/slow_cpu", DemoController, :slow_cpu
      get "/slow_query", DemoController, :slow_query
      get "/complex_query", DemoController, :complex_query
      get "/multiple_queries", DemoController, :multiple_queries
      get "/random_slow", DemoController, :random_slow
    end
  end

  # Development-only routes for performance monitoring
  if Mix.env() == :dev do
    scope "/dev/performance" do
      pipe_through :browser

      live "/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index
      live "/queries", ElixirDashboard.PerformanceLive.Queries, :index
      live "/errors", ElixirDashboard.PerformanceLive.Errors, :index
      live "/metrics", ElixirDashboard.PerformanceLive.Metrics, :index
      live "/events", ElixirDashboard.PerformanceLive.Events, :index
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:elixir_dashboard, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirDashboardWeb.Telemetry
    end
  end
end
