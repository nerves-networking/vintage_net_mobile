defmodule VintageNetLTE.MixProject do
  use Mix.Project

  def project do
    [
      app: :vintage_net_lte,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
#      {:vintage_net, "~> 0.7"},
      {:muontrap, "~> 0.5.0"}
    ]
  end
end
