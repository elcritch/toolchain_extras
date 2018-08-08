defmodule ToolchainExtras.MixProject do
  use Mix.Project

  @app :toolchain_extras

  def project do
    [
      app: @app,
      version: "0.2.3",
      elixir: "~> 1.4",
      nerves_package: [type: :toolchain_extras],
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  defp description do
    """
    ToolchainExtras - Basic module for adding "extra" toolchains to Nerves firmware builds. 
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Jaremy Creechley"],
      files: package_files(),
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/elcritch/#{@app}"}
    ]
  end

  defp package_files do
    [
      "README.md",
      "LICENSE",
      "mix.exs",
      "lib",
      "config"
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.0", runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
