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
    assigns = assign(assigns, :app_name, app_name())
    assigns = assign(assigns, :use_tracer, use_tracer_backend?())

    ~H"""
    <ElixirDashboardWeb.Components.PerformanceNav.performance_nav current_page={:endpoints} />
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">
          <%= @app_name %> - Slow API Endpoints
        </h1>
        <p class="text-sm text-gray-600 mb-4">
          Showing the 100 slowest endpoints recorded since the server started (threshold: 100ms).
          <%= if @use_tracer do %>
            <span class="inline-flex items-center px-2 py-1 ml-2 text-xs font-medium text-green-800 bg-green-100 rounded">
              Powered by ElixirTracer
            </span>
          <% end %>
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
              <%= if @use_tracer do %>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Status
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Errors
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Trace ID
                </th>
              <% end %>
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
                <%= if @use_tracer && Map.get(endpoint, :custom_attributes) && map_size(endpoint.custom_attributes) > 0 do %>
                  <div class="mt-2 space-y-1">
                    <!-- Phoenix metadata -->
                    <%= if get_in(endpoint.custom_attributes, ["phoenix.controller"]) do %>
                      <div class="text-xs text-gray-600">
                        <span class="font-semibold">Controller:</span>
                        <span class="text-purple-700">
                          <%= get_in(endpoint.custom_attributes, ["phoenix.controller"]) %>
                        </span>
                        <span class="mx-1">→</span>
                        <span class="text-purple-700">
                          <%= get_in(endpoint.custom_attributes, ["phoenix.action"]) %>
                        </span>
                      </div>
                    <% end %>
                    <!-- HTTP metadata -->
                    <%= if get_in(endpoint.custom_attributes, ["http.status_code"]) do %>
                      <div class="flex gap-2 text-xs">
                        <span class={[
                          "inline-flex items-center px-2 py-0.5 font-medium rounded",
                          status_badge_color(get_in(endpoint.custom_attributes, ["http.status_code"]))
                        ]}>
                          Status: <%= get_in(endpoint.custom_attributes, ["http.status_code"]) %>
                        </span>
                        <span class="inline-flex items-center px-2 py-0.5 font-medium text-gray-700 bg-gray-100 rounded">
                          <%= get_in(endpoint.custom_attributes, ["http.method"]) ||
                            get_in(endpoint.custom_attributes, ["request.method"]) %>
                        </span>
                      </div>
                    <% end %>
                    <!-- Database stats -->
                    <%= if endpoint.custom_attributes[:datastore_call_count] do %>
                      <div class="flex gap-2 text-xs">
                        <span class="inline-flex items-center px-2 py-0.5 font-medium text-blue-800 bg-blue-100 rounded">
                          <%= endpoint.custom_attributes[:datastore_call_count] %> DB queries
                        </span>
                        <span class="inline-flex items-center px-2 py-0.5 font-medium text-blue-800 bg-blue-100 rounded">
                          <%= endpoint.custom_attributes[:datastore_duration_ms] %>ms in DB
                        </span>
                      </div>
                    <% end %>
                    <!-- User/session data if present -->
                    <%= if endpoint.custom_attributes[:user_id] || endpoint.custom_attributes[:session_id] do %>
                      <div class="flex gap-2 text-xs">
                        <%= if endpoint.custom_attributes[:user_id] do %>
                          <span class="inline-flex items-center px-2 py-0.5 font-medium text-green-800 bg-green-100 rounded">
                            User: <%= endpoint.custom_attributes[:user_id] %>
                          </span>
                        <% end %>
                        <%= if endpoint.custom_attributes[:session_id] do %>
                          <span class="inline-flex items-center px-2 py-0.5 font-medium text-green-800 bg-green-100 rounded">
                            Session: <%= String.slice(
                              to_string(endpoint.custom_attributes[:session_id]),
                              0..7
                            ) %>...
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </td>
              <%= if @use_tracer do %>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={[
                    "inline-flex items-center px-2 py-1 text-xs font-medium rounded",
                    status_color(Map.get(endpoint, :status, :completed))
                  ]}>
                    <%= format_status(Map.get(endpoint, :status, :completed)) %>
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-center">
                  <%= if Map.get(endpoint, :error_count, 0) > 0 do %>
                    <span class="inline-flex items-center px-2 py-1 text-xs font-medium text-red-800 bg-red-100 rounded">
                      <%= endpoint.error_count %> error(s)
                    </span>
                  <% else %>
                    <span class="text-gray-400">-</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <%= if Map.get(endpoint, :trace_id) do %>
                    <span class="font-mono text-xs text-gray-600" title={endpoint.trace_id}>
                      <%= String.slice(endpoint.trace_id, 0..7) %>...
                    </span>
                  <% else %>
                    <span class="text-gray-400">-</span>
                  <% end %>
                </td>
              <% end %>
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

  defp status_color(:completed), do: "text-green-800 bg-green-100"
  defp status_color(:error), do: "text-red-800 bg-red-100"
  defp status_color(_), do: "text-gray-800 bg-gray-100"

  defp format_status(:completed), do: "✓ Success"
  defp format_status(:error), do: "✗ Error"
  defp format_status(status), do: to_string(status)

  defp status_badge_color(status) when status >= 200 and status < 300,
    do: "text-green-800 bg-green-100"

  defp status_badge_color(status) when status >= 300 and status < 400,
    do: "text-blue-800 bg-blue-100"

  defp status_badge_color(status) when status >= 400 and status < 500,
    do: "text-orange-800 bg-orange-100"

  defp status_badge_color(status) when status >= 500, do: "text-red-800 bg-red-100"
  defp status_badge_color(_), do: "text-gray-800 bg-gray-100"

  defp format_timestamp(milli) do
    milli
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp duration_color(ms) when ms > 1000, do: "text-red-600"
  defp duration_color(ms) when ms > 500, do: "text-orange-600"
  defp duration_color(ms) when ms > 200, do: "text-yellow-600"
  defp duration_color(_), do: "text-green-600"

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end

  defp use_tracer_backend? do
    Application.get_env(:elixir_dashboard, :storage_backend, :tracer) == :tracer
  end
end
