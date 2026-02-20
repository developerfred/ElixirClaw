defmodule ElixirClaw.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_claw,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript_config(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :public_key, :ssl],
      mod: {ElixirClaw.Application, []},
      config_providers: [{ElixirClaw.Config.Provider, []}]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mint, "~> 1.6"},
      {:mint_web_socket, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:confex, "~> 3.5"},
      {:telemetry, "~> 1.3"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_html, "~> 4.0"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end

  defp escript_config do
    [
      main_module: ElixirClaw.CLI,
      name: "elixir_claw",
      emacs: "elixir_claw"
    ]
  end

  defp aliases do
    [
      "deps.get": ["deps.get", "run -e 'IO.puts \"Dependencies ready\"'"]
    ]
  end
end
