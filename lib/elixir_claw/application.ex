defmodule ElixirClaw.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ElixirClaw.Registry},
      {Task.Supervisor, name: ElixirClaw.TaskSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: ElixirClaw.Gateway.Supervisor}
    ]

    opts = [strategy: :one_for_one, name: ElixirClaw.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
