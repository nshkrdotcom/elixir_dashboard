defmodule ElixirDashboardWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.
  """
  use ElixirDashboardWeb, :html

  embed_templates "page_html/*"
end
