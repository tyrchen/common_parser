defmodule Parser.MixProject do
  use Mix.Project

  @top File.cwd!()

  @version @top |> Path.join("version") |> File.read!() |> String.trim()
  @elixir_version @top
                  |> Path.join(".elixir_version")
                  |> File.read!()
                  |> String.trim()

  def project do
    [
      app: :common_parser,
      version: @version,
      elixir: @elixir_version,
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs", plt_add_apps: [:nimble_parsec]],
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
      {:nimble_parsec, "~> 0.5"},

      # dev & test
      {:benchee, "~> 0.13", only: :dev},
      {:benchee_html, "~> 0.4", only: :dev},
      {:credo, "~> 1.0.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :integration], runtime: false},
      {:ex_doc, "~> 0.19.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:test, :integration]},
      {:pre_commit_hook, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
