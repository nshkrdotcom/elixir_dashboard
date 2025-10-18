defmodule ElixirDashboardWeb.Components.PerformanceNav do
  @moduledoc """
  Navigation component for Performance Monitoring dashboards.
  """
  use Phoenix.Component

  @doc """
  Renders a navigation bar for the performance monitoring dashboards.

  ## Examples

      <.performance_nav current_page={:endpoints} />
      <.performance_nav current_page={:queries} />
  """
  attr :current_page, :atom, required: true

  def performance_nav(assigns) do
    ~H"""
    <nav class="bg-gray-800 mb-6">
      <div class="container mx-auto px-6">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center space-x-1">
            <.nav_link href="/dev/performance/endpoints" active={@current_page == :endpoints}>
              📊 Endpoints
            </.nav_link>
            <.nav_link href="/dev/performance/queries" active={@current_page == :queries}>
              🔍 Queries
            </.nav_link>
            <.nav_link href="/dev/performance/errors" active={@current_page == :errors}>
              ❌ Errors
            </.nav_link>
            <.nav_link href="/dev/performance/metrics" active={@current_page == :metrics}>
              📈 Metrics
            </.nav_link>
            <.nav_link href="/dev/performance/events" active={@current_page == :events}>
              🎉 Events
            </.nav_link>
          </div>
          <div class="text-gray-300 text-sm">
            <a href="/" class="hover:text-white transition">
              ← Home
            </a>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  attr :href, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "px-4 py-2 rounded-md text-sm font-medium transition",
        if(@active,
          do: "bg-gray-900 text-white",
          else: "text-gray-300 hover:bg-gray-700 hover:text-white"
        )
      ]}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
