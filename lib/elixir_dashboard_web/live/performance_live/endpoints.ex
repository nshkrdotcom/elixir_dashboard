defmodule ElixirDashboardWeb.PerformanceLive.Endpoints do
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

    endpoints = Store.get_slow_endpoints()
    {:ok, assign(socket, :endpoints, endpoints)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    endpoints = Store.get_slow_endpoints()
    {:noreply, assign(socket, :endpoints, endpoints)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    Store.clear_all()
    {:noreply, assign(socket, :endpoints, [])}
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
            <h1 class="picasso-title" style="margin-bottom: 0.5rem;">Slow Endpoints</h1>
            <p class="picasso-subtitle" style="margin: 0;">
              Showing the 100 slowest endpoints recorded (threshold: 100ms)
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
          :if={length(@endpoints) == 0}
          class="wright-panel"
          style="background: linear-gradient(135deg, rgba(74, 123, 167, 0.1) 0%, rgba(30, 58, 95, 0.05) 100%); border-left-color: var(--picasso-azure); border-right-color: var(--picasso-midnight);"
        >
          <p style="color: var(--picasso-azure); font-size: 1.1rem; margin: 0;">
            📊 No slow endpoints recorded yet. Start making requests to see data.
          </p>
        </div>

        <div :if={length(@endpoints) > 0} class="picasso-table-container">
          <table class="picasso-table">
            <thead>
              <tr>
                <th>Duration</th>
                <th>Endpoint Path</th>
                <th>Recorded At</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={endpoint <- @endpoints}>
                <td>
                  <span class={[
                    "picasso-duration-badge",
                    duration_class(endpoint.duration_ms)
                  ]}>
                    <%= endpoint.duration_ms %>ms
                  </span>
                </td>
                <td class="picasso-code-cell">
                  <%= endpoint.path %>
                </td>
                <td class="picasso-timestamp">
                  <%= format_timestamp(endpoint.timestamp) %>
                </td>
              </tr>
            </tbody>
          </table>
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

  defp duration_class(ms) when ms > 1000, do: "duration-critical"
  defp duration_class(ms) when ms > 500, do: "duration-high"
  defp duration_class(ms) when ms > 200, do: "duration-medium"
  defp duration_class(_), do: "duration-low"
end
