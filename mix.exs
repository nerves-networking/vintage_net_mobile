defmodule VintageNetLTE.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/nerves-networking/vintage_net_lte"

  def project do
    [
      app: :vintage_net_lte,
      version: @version,
      elixir: "~> 1.8",
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
      description: description()
    ]
  end

  def application do
    [
      env: [
        pppd_handler: VintageNetLTE.PPPDNotifications,
      ],
      extra_applications: [:logger],
      mod: {VintageNetLTE.Application, []}
    ]
  end

  defp description do
    "LTE support for VintageNet"
  end

  defp package do
    %{
      files: [
        "lib",
        "test",
        "mix.exs",
        "Makefile",
        "README.md",
        "src/*.[ch]",
        "src/test-c99.sh",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:vintage_net, github: "nerves-networking/vintage_net", branch: "master", override: true},
      {:muontrap, "~> 0.5.0"},
      {:ex_doc, "~> 0.19", only: :docs, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
