defmodule ElixirDashboard.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/yourorg/elixir_dashboard"

  def project do
    [
      app: :elixir_dashboard,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Elixir Dashboard",
      source_url: @source_url
    ]
  end

  def application do
    [
      mod: application_mod(Mix.env()),
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Only start the full demo app in dev/test, not when used as a library
  defp application_mod(:dev), do: {ElixirDashboard.Application, []}
  defp application_mod(:test), do: {ElixirDashboard.Application, []}
  defp application_mod(_), do: {ElixirDashboard.LibApplication, []}

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core library dependencies - required for LiveView components
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:telemetry, "~> 1.0"},

      # Demo/dev app dependencies
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8", optional: true},
      {:telemetry_metrics, "~> 0.6", optional: true},
      {:telemetry_poller, "~> 1.0", optional: true},
      {:jason, "~> 1.2", optional: true},
      {:dns_cluster, "~> 0.1.1", only: [:dev, :test]},
      {:bandit, "~> 1.0", only: [:dev, :test]},
      {:floki, ">= 0.30.0", only: :test},

      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A Phoenix LiveView performance monitoring dashboard for tracking slow endpoints and database queries during development.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "SETUP.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "dev.server": ["phx.server"]
    ]
  end
end
