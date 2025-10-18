defmodule ElixirDashboard.PerformanceLive.Queries do
  @moduledoc """
  LiveView component for displaying slow query performance data.
  """
  use Phoenix.LiveView

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
    assigns = assign(assigns, :app_name, app_name())
    assigns = assign(assigns, :use_tracer, use_tracer_backend?())

    ~H"""
    <ElixirDashboardWeb.Components.PerformanceNav.performance_nav current_page={:queries} />
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2"><%= @app_name %> - Slow SQL Queries</h1>
        <p class="text-sm text-gray-600 mb-4">
          Showing the 100 slowest queries recorded since the server started (threshold: 50ms).
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

      <div :if={length(@queries) == 0} class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p class="text-blue-800">
          No slow queries recorded yet. Start making database requests to see data.
        </p>
      </div>

      <div :if={length(@queries) > 0} class="space-y-4">
        <div
          :for={query <- @queries}
          class="bg-white shadow-md rounded-lg overflow-hidden hover:shadow-lg transition"
        >
          <div class="p-5">
            <div class="flex justify-between items-baseline mb-3">
              <div class="flex items-baseline gap-3">
                <span class={[
                  "text-xl font-bold",
                  duration_color(query.duration_ms)
                ]}>
                  <%= query.duration_ms %>ms
                </span>
                <%= if @use_tracer && Map.get(query, :db_operation) do %>
                  <span class="inline-flex items-center px-2 py-1 text-xs font-medium text-purple-800 bg-purple-100 rounded">
                    <%= query.db_operation %>
                  </span>
                  <%= if Map.get(query, :db_table) do %>
                    <span class="inline-flex items-center px-2 py-1 text-xs font-medium text-blue-800 bg-blue-100 rounded">
                      <%= query.db_table %>
                    </span>
                  <% end %>
                <% end %>
              </div>
              <span class="text-sm text-gray-500">
                <%= format_timestamp(query.timestamp) %>
              </span>
            </div>

            <div class="mb-3">
              <p class="text-sm text-gray-600">
                <span class="font-semibold">Endpoint:</span>
                <span class="font-mono ml-2 text-gray-800"><%= query.endpoint_path %></span>
              </p>
              <%= if @use_tracer do %>
                <div class="mt-2 flex gap-4 text-xs text-gray-500">
                  <%= if Map.get(query, :db_instance) do %>
                    <span><span class="font-semibold">Database:</span> <%= query.db_instance %></span>
                  <% end %>
                  <%= if Map.get(query, :peer_hostname) do %>
                    <span><span class="font-semibold">Host:</span> <%= query.peer_hostname %></span>
                  <% end %>
                  <%= if Map.get(query, :span_id) do %>
                    <span>
                      <span class="font-semibold">Span ID:</span>
                      <span class="font-mono"><%= String.slice(query.span_id, 0..7) %>...</span>
                    </span>
                  <% end %>
                </div>
              <% end %>
            </div>

            <div class="bg-gray-50 rounded-md p-3 border border-gray-200">
              <p class="text-xs text-gray-500 mb-1 font-semibold">SQL Query:</p>
              <pre class="text-sm overflow-x-auto whitespace-pre-wrap break-words font-mono text-gray-800"><code><%= query.query %></code></pre>
            </div>

            <div
              :if={query.params && length(query.params) > 0}
              class="mt-3 bg-blue-50 rounded-md p-3 border border-blue-200"
            >
              <p class="text-xs text-blue-700 mb-1 font-semibold">Parameters:</p>
              <pre class="text-sm overflow-x-auto whitespace-pre-wrap break-words font-mono text-blue-900"><code><%= inspect(query.params, pretty: true) %></code></pre>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_timestamp(milli) do
    milli
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp duration_color(ms) when ms > 500, do: "text-red-600"
  defp duration_color(ms) when ms > 200, do: "text-orange-600"
  defp duration_color(ms) when ms > 100, do: "text-yellow-600"
  defp duration_color(_), do: "text-green-600"

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end

  defp use_tracer_backend? do
    Application.get_env(:elixir_dashboard, :storage_backend, :tracer) == :tracer
  end
end
