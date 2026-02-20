defmodule ElixirClaw.Application do
  @moduledoc false
  use Application

  def application do
    [
      extra_applications: [:logger, :crypto, :public_key, :ssl],
      mod: {ElixirClaw.Application, []},
      config_providers: [{ElixirClaw.Config.Provider, []}]
    ]
  end

  @impl true
  def start(_type, args) do
    children = build_children(args)

    opts = [strategy: :one_for_one, name: ElixirClaw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp build_children(_args) do
    base_children = [
      {Registry, keys: :unique, name: ElixirClaw.Registry},
      {Task.Supervisor, name: ElixirClaw.TaskSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: ElixirClaw.Gateway.Supervisor}
    ]

    if Application.get_env(:elixir_claw, :start_dashboard, false) do
      base_children ++ [{ElixirClawWeb.Endpoint, []}]
    else
      base_children
    end
  end
end
