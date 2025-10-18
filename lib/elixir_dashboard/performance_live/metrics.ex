defmodule ElixirDashboard.PerformanceLive.Metrics do
  @moduledoc """
  LiveView component for displaying aggregated performance metrics from ElixirTracer.

  Shows:
  - Datastore metrics (database operations)
  - External metrics (HTTP calls)
  - Custom metrics
  - Call counts, durations, min/max/avg
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :refresh)
    end

    metrics = get_metrics()
    grouped = group_metrics(metrics)

    {:ok, assign(socket, metrics: metrics, grouped: grouped, filter: :all)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    metrics = get_metrics()
    grouped = group_metrics(metrics)
    {:noreply, assign(socket, metrics: metrics, grouped: grouped)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    ElixirTracer.Query.clear_all()
    {:noreply, assign(socket, metrics: [], grouped: %{}, filter: :all)}
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) do
    filter = String.to_existing_atom(type)
    {:noreply, assign(socket, filter: filter)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :app_name, app_name())
    assigns = assign(assigns, :filtered_metrics, filter_metrics(assigns.grouped, assigns.filter))

    ~H"""
    <ElixirDashboardWeb.Components.PerformanceNav.performance_nav current_page={:metrics} />
    <div class="wright-container">
      <div class="horizontal-band"></div>

      <div class="picasso-card">
        <div class="cubist-pattern"></div>

        <div class="mb-6">
          <h1 class="picasso-title" style="margin-bottom: 0.5rem;">
            <%= @app_name %> - Performance Metrics
          </h1>
          <p class="text-sm text-gray-600 mb-4">
            Aggregated performance data for database, external services, and custom metrics.
            <span class="inline-flex items-center px-2 py-1 ml-2 text-xs font-medium text-green-800 bg-green-100 rounded">
              Powered by ElixirTracer
            </span>
          </p>
          <div class="flex gap-2">
            <button
              phx-click="clear"
              class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition"
            >
              Clear Data
            </button>
          </div>
        </div>
        <!-- Filter Tabs -->
        <div class="mb-6 border-b border-gray-200">
          <nav class="-mb-px flex space-x-8">
            <button
              phx-click="filter"
              phx-value-type="all"
              class={["py-4 px-1 border-b-2 font-medium text-sm", filter_tab_class(@filter == :all)]}
            >
              All Metrics (<%= total_count(@grouped) %>)
            </button>
            <button
              phx-click="filter"
              phx-value-type="datastore"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                filter_tab_class(@filter == :datastore)
              ]}
            >
              Database (<%= length(Map.get(@grouped, :datastore, [])) %>)
            </button>
            <button
              phx-click="filter"
              phx-value-type="external"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                filter_tab_class(@filter == :external)
              ]}
            >
              External (<%= length(Map.get(@grouped, :external, [])) %>)
            </button>
            <button
              phx-click="filter"
              phx-value-type="custom"
              class={[
                "py-4 px-1 border-b-2 font-medium text-sm",
                filter_tab_class(@filter == :custom)
              ]}
            >
              Custom (<%= length(Map.get(@grouped, :custom, [])) %>)
            </button>
          </nav>
        </div>

        <div
          :if={filtered_metrics_empty?(@filtered_metrics)}
          class="bg-blue-50 border border-blue-200 rounded-lg p-4"
        >
          <p class="text-blue-800">
            No metrics recorded yet for this category.
          </p>
        </div>
        <!-- Metrics Table -->
        <div
          :if={!filtered_metrics_empty?(@filtered_metrics)}
          class="bg-white shadow-md rounded-lg overflow-hidden"
        >
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Metric Name
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Calls
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Total Time
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Avg
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Min
                </th>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Max
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {_category, metrics_in_category} <- @filtered_metrics, metric <- metrics_in_category do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-6 py-4">
                    <div class="text-sm font-medium text-gray-900 font-mono">
                      <%= metric.name %>
                    </div>
                    <%= if metric_category(metric.name) do %>
                      <div class="text-xs text-gray-500 mt-1">
                        <span class={[
                          "inline-flex items-center px-2 py-0.5 rounded",
                          category_badge_class(metric_category(metric.name))
                        ]}>
                          <%= metric_category(metric.name) %>
                        </span>
                      </div>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= metric.call_count %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    <%= format_duration(metric.total_call_time) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    <%= format_duration(metric.total_call_time / metric.call_count) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600">
                    <%= format_duration(metric.min_call_time) %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-red-600">
                    <%= format_duration(metric.max_call_time) %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <div class="horizontal-band" style="margin-top: 2rem;"></div>
    </div>
    """
  end

  # Private Functions

  defp get_metrics do
    ElixirTracer.Query.get_metrics()
    |> Enum.sort_by(& &1.total_call_time, :desc)
  end

  defp group_metrics(metrics) do
    Enum.group_by(metrics, fn metric ->
      cond do
        String.starts_with?(metric.name, "Datastore/") -> :datastore
        String.starts_with?(metric.name, "External/") -> :external
        true -> :custom
      end
    end)
  end

  defp filter_metrics(grouped, :all), do: grouped
  defp filter_metrics(grouped, category), do: %{category => Map.get(grouped, category, [])}

  defp filtered_metrics_empty?(filtered) do
    filtered
    |> Map.values()
    |> Enum.all?(&(&1 == []))
  end

  defp total_count(grouped) do
    grouped
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.sum()
  end

  defp filter_tab_class(true), do: "border-blue-500 text-blue-600"

  defp filter_tab_class(false),
    do: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"

  defp metric_category(name) do
    cond do
      String.starts_with?(name, "Datastore/") -> "Database"
      String.starts_with?(name, "External/") -> "External"
      String.starts_with?(name, "Custom/") -> "Custom"
      true -> nil
    end
  end

  defp category_badge_class("Database"), do: "text-purple-800 bg-purple-100"
  defp category_badge_class("External"), do: "text-blue-800 bg-blue-100"
  defp category_badge_class("Custom"), do: "text-green-800 bg-green-100"
  defp category_badge_class(_), do: "text-gray-800 bg-gray-100"

  defp format_duration(seconds) when is_float(seconds) or is_integer(seconds) do
    cond do
      seconds < 0.001 -> "#{Float.round(seconds * 1_000_000, 2)}μs"
      seconds < 1.0 -> "#{Float.round(seconds * 1000, 2)}ms"
      true -> "#{Float.round(seconds, 3)}s"
    end
  end

  defp format_duration(_), do: "N/A"

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end
end
