defmodule ElixirDashboard.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/nshkrdotcom/elixir_dashboard"

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
      name: "ElixirDashboard",
      source_url: @source_url,
      homepage_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :inets],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      mod: application_mod(Mix.env()),
      extra_applications: [:logger, :runtime_tools, :crypto]
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
      {:elixir_tracer, "~> 0.1.0"},

      # Demo/dev app dependencies
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8", optional: true},
      {:telemetry_metrics, "~> 0.6", optional: true},
      {:telemetry_poller, "~> 1.0", optional: true},
      {:jason, "~> 1.2", optional: true},
      {:dns_cluster, "~> 0.1.1", only: [:dev, :test]},
      {:bandit, "~> 1.0", only: [:dev, :test]},
      {:floki, ">= 0.30.0", only: :test},

      # Database for demo/dev app (for real slow query testing)
      {:ecto_sql, "~> 3.10", only: [:dev, :test]},
      {:postgrex, "~> 0.17", only: [:dev, :test]},

      # Development and testing
      {:ex_doc, "~> 0.40.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:supertester, "~> 0.5.1", only: :test}
    ]
  end

  defp description do
    """
    A Phoenix LiveView performance monitoring dashboard for tracking slow endpoints and database queries during development.
    """
  end

  defp package do
    [
      name: "elixir_dashboard",
      description: description(),
      files:
        ~w(lib assets .formatter.exs mix.exs README.md INTEGRATION_GUIDE.md SETUP.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Online documentation" => "https://hexdocs.pm/elixir_dashboard",
        "Integration Guide" => "https://hexdocs.pm/elixir_dashboard/INTEGRATION_GUIDE.html",
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md"
      },
      maintainers: ["nshkrdotcom"],
      exclude_patterns: [
        "priv/plts",
        ".DS_Store"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "ElixirDashboard",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      logo: "assets/elixir_dashboard.svg",
      extras: [
        "README.md",
        "INTEGRATION_GUIDE.md",
        "LIBRARY_USAGE.md",
        "SETUP.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      groups_for_extras: [
        "Getting Started": ["README.md", "INTEGRATION_GUIDE.md"],
        Advanced: ["LIBRARY_USAGE.md", "SETUP.md"],
        "Release Notes": ["CHANGELOG.md"]
      ],
      groups_for_modules: [
        "Core API": [
          ElixirDashboard,
          ElixirDashboard.PerformanceMonitor
        ],
        "Performance Monitoring": [
          ElixirDashboard.PerformanceMonitor.Store,
          ElixirDashboard.PerformanceMonitor.TelemetryHandler,
          ElixirDashboard.PerformanceMonitor.Supervisor
        ],
        "LiveView Components": [
          ElixirDashboard.PerformanceLive.Endpoints,
          ElixirDashboard.PerformanceLive.Queries
        ]
      ],
      before_closing_head_tag: fn
        :html ->
          """
          <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
          <script>
            let initialized = false;

            window.addEventListener("exdoc:loaded", () => {
              if (!initialized) {
                mermaid.initialize({
                  startOnLoad: false,
                  theme: document.body.className.includes("dark") ? "dark" : "default"
                });
                initialized = true;
              }

              let id = 0;
              for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
                const preEl = codeEl.parentElement;
                const graphDefinition = codeEl.textContent;
                const graphEl = document.createElement("div");
                const graphId = "mermaid-graph-" + id++;
                mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
                  graphEl.innerHTML = svg;
                  bindFunctions?.(graphEl);
                  preEl.insertAdjacentElement("afterend", graphEl);
                  preEl.remove();
                });
              }
            });
          </script>
          """

        _ ->
          ""
      end
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "dev.server": ["phx.server"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
