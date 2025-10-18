defmodule ElixirDashboard.PerformanceLive.Errors do
  @moduledoc """
  LiveView component for displaying error traces from ElixirTracer.

  Shows captured exceptions with full context including:
  - Error type and message
  - Stack traces
  - Transaction correlation
  - Custom attributes
  - Timestamp and frequency
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh data every 5 seconds
      :timer.send_interval(5000, self(), :refresh)
    end

    errors = get_errors()
    stats = calculate_stats(errors)

    {:ok, assign(socket, errors: errors, stats: stats)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    errors = get_errors()
    stats = calculate_stats(errors)
    {:noreply, assign(socket, errors: errors, stats: stats)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    ElixirTracer.Query.clear_all()
    {:noreply, assign(socket, errors: [], stats: %{})}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :app_name, app_name())

    ~H"""
    <ElixirDashboardWeb.Components.PerformanceNav.performance_nav current_page={:errors} />
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">
          <%= @app_name %> - Error Traces
        </h1>
        <p class="text-sm text-gray-600 mb-4">
          All captured exceptions with full context and stack traces.
          <span class="inline-flex items-center px-2 py-1 ml-2 text-xs font-medium text-green-800 bg-green-100 rounded">
            Powered by ElixirTracer
          </span>
        </p>
        <button
          phx-click="clear"
          class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
        >
          Clear Data
        </button>
      </div>

      <%= if map_size(@stats) > 0 do %>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Total Errors</div>
            <div class="mt-1 text-3xl font-semibold text-red-600"><%= @stats.total %></div>
          </div>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Error Types</div>
            <div class="mt-1 text-3xl font-semibold text-gray-900"><%= @stats.types_count %></div>
          </div>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Most Common</div>
            <div class="mt-1 text-lg font-semibold text-gray-900"><%= @stats.most_common %></div>
          </div>
        </div>
      <% end %>

      <div :if={length(@errors) == 0} class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p class="text-blue-800">
          No errors recorded yet. Errors will appear here when exceptions occur.
        </p>
      </div>

      <div :if={length(@errors) > 0} class="space-y-4">
        <div
          :for={error <- @errors}
          class="bg-white shadow-md rounded-lg overflow-hidden hover:shadow-lg transition border-l-4 border-red-500"
        >
          <div class="p-5">
            <!-- Error Header -->
            <div class="flex justify-between items-start mb-3">
              <div class="flex-1">
                <div class="flex items-center gap-3 mb-2">
                  <span class="inline-flex items-center px-3 py-1 text-sm font-medium text-red-800 bg-red-100 rounded">
                    <%= error.error_type %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= format_timestamp(error.timestamp) %>
                  </span>
                </div>
                <h3 class="text-lg font-semibold text-gray-900 mb-1">
                  <%= error.message %>
                </h3>
              </div>
            </div>
            <!-- Transaction Info -->
            <%= if error.transaction_name do %>
              <div class="mb-3 p-3 bg-gray-50 rounded border border-gray-200">
                <div class="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span class="font-semibold text-gray-600">Transaction:</span>
                    <span class="font-mono text-gray-900 ml-2"><%= error.transaction_name %></span>
                  </div>
                  <%= if error.transaction_id do %>
                    <div>
                      <span class="font-semibold text-gray-600">Transaction ID:</span>
                      <span class="font-mono text-xs text-gray-700 ml-2">
                        <%= String.slice(error.transaction_id, 0..15) %>...
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
            <!-- Custom Attributes -->
            <%= if error.user_attributes && map_size(error.user_attributes) > 0 do %>
              <div class="mb-3">
                <p class="text-xs text-gray-600 mb-2 font-semibold">Context:</p>
                <div class="flex flex-wrap gap-2">
                  <%= for {key, value} <- error.user_attributes do %>
                    <span class="inline-flex items-center px-2 py-1 text-xs font-medium text-blue-800 bg-blue-100 rounded">
                      <%= key %>: <%= inspect(value) %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
            <!-- Stack Trace -->
            <%= if error.stack_trace && error.stack_trace != "" do %>
              <details class="mt-3">
                <summary class="cursor-pointer text-sm font-semibold text-gray-700 hover:text-gray-900">
                  Stack Trace
                </summary>
                <div class="mt-2 bg-gray-900 rounded-md p-3 overflow-x-auto">
                  <pre class="text-xs text-green-400 font-mono"><code><%= error.stack_trace %></code></pre>
                </div>
              </details>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private Functions

  defp get_errors do
    ElixirTracer.Query.get_errors(limit: 100)
    |> Enum.sort_by(& &1.timestamp, :desc)
  end

  defp calculate_stats(errors) do
    if length(errors) == 0 do
      %{}
    else
      types = Enum.group_by(errors, & &1.error_type)

      most_common =
        types
        |> Enum.max_by(fn {_type, errs} -> length(errs) end, fn -> {nil, []} end)
        |> elem(0)

      %{
        total: length(errors),
        types_count: map_size(types),
        most_common: most_common || "N/A"
      }
    end
  end

  defp format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end
end
