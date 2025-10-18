defmodule ElixirDashboardWeb.PageController do
  use ElixirDashboardWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
