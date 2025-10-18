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
    <div class="wright-container">
      <div class="horizontal-band"></div>

      <div class="picasso-card">
        <div class="cubist-pattern"></div>

        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 2rem;">
          <div>
            <h1 class="picasso-title" style="margin-bottom: 0.5rem;">
              <%= @app_name %> - Slow Endpoints
            </h1>
            <p class="picasso-subtitle" style="margin: 0;">
              Showing the 100 slowest endpoints (threshold: 100ms)
              <%= if @use_tracer do %>
                <span
                  class="picasso-new-badge"
                  style="background: var(--picasso-mint); color: var(--picasso-deep-blue); margin-left: 0.5rem;"
                >
                  ElixirTracer
                </span>
              <% end %>
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
                <%= if @use_tracer do %>
                  <th>Status</th>
                  <th>Errors</th>
                  <th>Trace ID</th>
                <% end %>
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
                            status_badge_color(
                              get_in(endpoint.custom_attributes, ["http.status_code"])
                            )
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
                <td class="picasso-timestamp">
                  <%= format_timestamp(endpoint.timestamp) %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="horizontal-band" style="margin-top: 2rem;"></div>
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

  defp duration_class(ms) when ms > 1000, do: "duration-critical"
  defp duration_class(ms) when ms > 500, do: "duration-high"
  defp duration_class(ms) when ms > 200, do: "duration-medium"
  defp duration_class(_), do: "duration-low"

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end

  defp use_tracer_backend? do
    Application.get_env(:elixir_dashboard, :storage_backend, :tracer) == :tracer
  end
end
