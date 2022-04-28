defmodule VintageNetMobile.MixProject do
  use Mix.Project

  @version "0.11.0"
  @source_url "https://github.com/nerves-networking/vintage_net_mobile"

  def project do
    [
      app: :vintage_net_mobile,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      make_error_message: "",
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs,
        credo: :test,
        "coveralls.circle": :test
      }
    ]
  end

  def application do
    [
      env: [
        pppd_handler: VintageNetMobile.PPPDNotifications
      ],
      extra_applications: [:logger],
      mod: {VintageNetMobile.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Mobile connection support for VintageNet"
  end

  defp package do
    %{
      files: [
        "lib",
        "mix.exs",
        "Makefile",
        "README.md",
        "c_src",
        "src/at_lexer.xrl",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:vintage_net, "~> 0.10.4 or ~> 0.11.0 or ~> 0.12.0"},
      {:circuits_uart, "~> 1.4"},
      {:muontrap, "~> 1.0.0 or ~> 0.6.0"},
      {:elixir_make, "~> 0.6", runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
