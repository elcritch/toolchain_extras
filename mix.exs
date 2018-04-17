defmodule ToolchainExtras.MixProject do
  use Mix.Project

  def project do
    [
      app: :toolchain_extras,
      version: "0.1.1",
      elixir: "~> 1.4",
      nerves_package: [type: :toolchain_extras],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.0-rc.1", runtime: false},
    ]
  end
end
