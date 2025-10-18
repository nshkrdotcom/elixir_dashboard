defmodule ElixirDashboardWeb.PerformanceLive.Queries do
  @moduledoc """
  Demo app wrapper - delegates to the library LiveView.
  """
  use ElixirDashboardWeb, :live_view

  alias ElixirDashboard.PerformanceMonitor.Store

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh data every 5 seconds
      :timer.send_interval(5000, self(), :refresh)
    end

    queries = Store.get_slow_queries()
    {:ok, assign(socket, :queries, queries)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    queries = Store.get_slow_queries()
    {:noreply, assign(socket, :queries, queries)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    Store.clear_all()
    {:noreply, assign(socket, :queries, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="wright-container">
      <div class="horizontal-band"></div>

      <div class="picasso-card">
        <div class="cubist-pattern"></div>

        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 2rem;">
          <div>
            <h1 class="picasso-title" style="margin-bottom: 0.5rem;">Slow SQL Queries</h1>
            <p class="picasso-subtitle" style="margin: 0;">
              Showing the 100 slowest queries recorded (threshold: 50ms)
            </p>
          </div>
          <button
            phx-click="clear"
            class="picasso-btn picasso-btn-red"
            style="width: auto; padding: 1rem 2rem; border: none; margin: 0;"
          >
            <span>🗑️</span>
            <span>Clear Data</span>
          </button>
        </div>

        <div class="horizontal-band-thin"></div>

        <div
          :if={length(@queries) == 0}
          class="wright-panel"
          style="background: linear-gradient(135deg, rgba(74, 123, 167, 0.1) 0%, rgba(30, 58, 95, 0.05) 100%); border-left-color: var(--picasso-azure); border-right-color: var(--picasso-midnight);"
        >
          <p style="color: var(--picasso-azure); font-size: 1.1rem; margin: 0;">
            🔍 No slow queries recorded yet. Start making database requests to see data.
          </p>
        </div>

        <div :if={length(@queries) > 0} class="picasso-query-list">
          <div :for={query <- @queries} class="picasso-query-card">
            <div class="picasso-query-header">
              <span class={[
                "picasso-duration-badge",
                duration_class(query.duration_ms)
              ]}>
                <%= query.duration_ms %>ms
              </span>
              <span class="picasso-timestamp">
                <%= format_timestamp(query.timestamp) %>
              </span>
            </div>

            <div class="picasso-query-endpoint">
              <span style="color: var(--picasso-umber); font-weight: 700;">Endpoint:</span>
              <span class="picasso-code-inline"><%= query.endpoint_path %></span>
            </div>

            <div class="picasso-sql-block">
              <div class="picasso-sql-label">SQL Query:</div>
              <pre class="picasso-sql-code"><code><%= query.query %></code></pre>
            </div>

            <div :if={query.params && length(query.params) > 0} class="picasso-params-block">
              <div class="picasso-params-label">Parameters:</div>
              <pre class="picasso-params-code"><code><%= inspect(query.params, pretty: true) %></code></pre>
            </div>
          </div>
        </div>
      </div>

      <div class="horizontal-band" style="margin-top: 2rem;"></div>
    </div>
    """
  end

  defp format_timestamp(milli) do
    milli
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp duration_class(ms) when ms > 500, do: "duration-critical"
  defp duration_class(ms) when ms > 200, do: "duration-high"
  defp duration_class(ms) when ms > 100, do: "duration-medium"
  defp duration_class(_), do: "duration-low"
end
