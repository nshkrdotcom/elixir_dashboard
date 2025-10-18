defmodule ElixirDashboard.PerformanceLive.Endpoints do
  @moduledoc """
  LiveView component for displaying slow endpoint performance data.

  ## Usage in your Phoenix app

  In your router.ex:

      scope "/dev" do
        pipe_through :browser

        live "/performance/endpoints", ElixirDashboard.PerformanceLive.Endpoints, :index
      end
  """
  use Phoenix.LiveView

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
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Slow API Endpoints</h1>
        <p class="text-sm text-gray-600 mb-4">
          Showing the 100 slowest endpoints recorded since the server started (threshold: 100ms).
        </p>
        <button
          phx-click="clear"
          class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
        >
          Clear Data
        </button>
      </div>

      <div :if={length(@endpoints) == 0} class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p class="text-blue-800">
          No slow endpoints recorded yet. Start making requests to see data.
        </p>
      </div>

      <div :if={length(@endpoints) > 0} class="bg-white shadow-md rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Duration (ms)
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Endpoint Path
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Recorded At
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr :for={endpoint <- @endpoints} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={[
                  "font-mono font-semibold",
                  duration_color(endpoint.duration_ms)
                ]}>
                  <%= endpoint.duration_ms %>ms
                </span>
              </td>
              <td class="px-6 py-4 font-mono text-sm text-gray-900">
                <%= endpoint.path %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <%= format_timestamp(endpoint.timestamp) %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp format_timestamp(milli) do
    milli
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp duration_color(ms) when ms > 1000, do: "text-red-600"
  defp duration_color(ms) when ms > 500, do: "text-orange-600"
  defp duration_color(ms) when ms > 200, do: "text-yellow-600"
  defp duration_color(_), do: "text-green-600"
end
