defmodule ElixirDashboardWeb.Repo do
  @moduledoc """
  Demo Ecto repository for testing slow queries.
  Only used in dev/test environments.
  """
  use Ecto.Repo,
    otp_app: :elixir_dashboard,
    adapter: Ecto.Adapters.Postgres
end
