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
    <nav class="picasso-subnav">
      <div class="picasso-subnav-container">
        <div class="picasso-subnav-content">
          <div class="picasso-subnav-links">
            <.nav_link href="/dev/performance/endpoints" active={@current_page == :endpoints}>
              Endpoints
            </.nav_link>
            <.nav_link href="/dev/performance/queries" active={@current_page == :queries}>
              Queries
            </.nav_link>
            <.nav_link href="/dev/performance/errors" active={@current_page == :errors}>
              Errors
            </.nav_link>
            <.nav_link href="/dev/performance/metrics" active={@current_page == :metrics}>
              Metrics
            </.nav_link>
            <.nav_link href="/dev/performance/events" active={@current_page == :events}>
              Events
            </.nav_link>
          </div>
          <div class="picasso-subnav-home">
            <a href="/" class="picasso-subnav-home-link">
              Home
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
        "picasso-subnav-link",
        if(@active, do: "picasso-subnav-link-active", else: "")
      ]}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
