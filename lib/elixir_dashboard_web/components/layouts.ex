defmodule ElixirDashboardWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.
  """
  use ElixirDashboardWeb, :html

  embed_templates "layouts/*"

  @doc """
  Returns the configured application name for display in UI.

  Configure in config/dev.exs:

      config :elixir_dashboard, :app_name, "MyApp Dashboard"

  Defaults to "ElixirDashboard" if not configured.
  """
  def app_name do
    Application.get_env(:elixir_dashboard, :app_name, "ElixirDashboard")
  end
end
