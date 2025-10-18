defmodule ElixirDashboard.PerformanceLive.Events do
  @moduledoc """
  LiveView component for displaying custom events from ElixirTracer.

  Shows business events like:
  - User signups
  - Purchases
  - Feature usage
  - Custom application events
  """
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :refresh)
    end

    events = get_events()
    stats = calculate_stats(events)

    {:ok, assign(socket, events: events, stats: stats, filter_type: nil)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    events = get_events()
    stats = calculate_stats(events)
    {:noreply, assign(socket, events: events, stats: stats)}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    ElixirTracer.Query.clear_all()
    {:noreply, assign(socket, events: [], stats: %{}, filter_type: nil)}
  end

  @impl true
  def handle_event("filter", %{"type" => ""}, socket) do
    {:noreply, assign(socket, filter_type: nil)}
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) do
    {:noreply, assign(socket, filter_type: type)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :app_name, app_name())

    assigns =
      assign(assigns, :filtered_events, filter_events(assigns.events, assigns.filter_type))

    assigns = assign(assigns, :event_types, get_event_types(assigns.events))

    ~H"""
    <ElixirDashboardWeb.Components.PerformanceNav.performance_nav current_page={:events} />
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">
          <%= @app_name %> - Custom Events
        </h1>
        <p class="text-sm text-gray-600 mb-4">
          Business events and custom application tracking.
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
      <!-- Stats Cards -->
      <%= if map_size(@stats) > 0 do %>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Total Events</div>
            <div class="mt-1 text-3xl font-semibold text-blue-600"><%= @stats.total %></div>
          </div>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Event Types</div>
            <div class="mt-1 text-3xl font-semibold text-gray-900"><%= @stats.types_count %></div>
          </div>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Most Common</div>
            <div class="mt-1 text-lg font-semibold text-gray-900">
              <%= @stats.most_common || "N/A" %>
            </div>
            <%= if @stats.most_common_count do %>
              <div class="text-xs text-gray-500"><%= @stats.most_common_count %> occurrences</div>
            <% end %>
          </div>
          <div class="bg-white shadow rounded-lg p-4">
            <div class="text-sm font-medium text-gray-500">Last Hour</div>
            <div class="mt-1 text-3xl font-semibold text-green-600"><%= @stats.last_hour %></div>
          </div>
        </div>
      <% end %>
      <!-- Filter -->
      <%= if length(@event_types) > 0 do %>
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-2">Filter by Event Type:</label>
          <select
            phx-change="filter"
            name="type"
            class="mt-1 block w-full md:w-64 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
          >
            <option value="">All Events (<%= length(@events) %>)</option>
            <%= for {type, count} <- @event_types do %>
              <option value={type} selected={@filter_type == type}>
                <%= type %> (<%= count %>)
              </option>
            <% end %>
          </select>
        </div>
      <% end %>

      <div
        :if={length(@filtered_events) == 0}
        class="bg-blue-50 border border-blue-200 rounded-lg p-4"
      >
        <p class="text-blue-800">
          No custom events recorded yet. Events will appear when you use ElixirTracer.CustomEvent.Reporter.report_custom_event/2.
        </p>
      </div>
      <!-- Events List -->
      <div :if={length(@filtered_events) > 0} class="space-y-3">
        <div
          :for={event <- @filtered_events}
          class="bg-white shadow rounded-lg overflow-hidden hover:shadow-md transition"
        >
          <div class="p-4">
            <div class="flex justify-between items-start mb-3">
              <div class="flex items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 text-sm font-semibold text-blue-800 bg-blue-100 rounded">
                  <%= event.type %>
                </span>
                <span class="text-sm text-gray-500">
                  <%= format_timestamp(event.timestamp) %>
                </span>
              </div>
            </div>

            <%= if event.attributes && map_size(event.attributes) > 0 do %>
              <div class="bg-gray-50 rounded p-3 border border-gray-200">
                <p class="text-xs text-gray-600 mb-2 font-semibold">Event Data:</p>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                  <%= for {key, value} <- event.attributes do %>
                    <div class="text-sm">
                      <span class="font-medium text-gray-700"><%= key %>:</span>
                      <span class="ml-2 text-gray-900"><%= format_value(value) %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private Functions

  defp get_events do
    ElixirTracer.Query.get_custom_events()
    |> Enum.sort_by(& &1.timestamp, :desc)
  end

  defp filter_events(events, nil), do: events

  defp filter_events(events, type) do
    Enum.filter(events, &(&1.type == type))
  end

  defp get_event_types(events) do
    events
    |> Enum.group_by(& &1.type)
    |> Enum.map(fn {type, evs} -> {type, length(evs)} end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
  end

  defp calculate_stats(events) do
    if length(events) == 0 do
      %{
        total: 0,
        types_count: 0,
        most_common: nil,
        most_common_count: 0,
        last_hour: 0
      }
    else
      one_hour_ago = System.system_time(:millisecond) - 3_600_000
      last_hour = Enum.count(events, &(&1.timestamp >= one_hour_ago))

      grouped = Enum.group_by(events, & &1.type)

      {most_common, most_common_events} =
        Enum.max_by(grouped, fn {_type, evs} -> length(evs) end, fn -> {nil, []} end)

      %{
        total: length(events),
        types_count: map_size(grouped),
        most_common: most_common,
        most_common_count: length(most_common_events),
        last_hour: last_hour
      }
    end
  end

  defp format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_number(value), do: to_string(value)
  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value), do: inspect(value)

  defp app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end
end
