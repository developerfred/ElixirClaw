defmodule ElixirClaw.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    load_config()

    children = [
      {Registry, keys: :unique, name: ElixirClaw.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ElixirClaw.Gateway.Supervisor}
    ]

    opts = [strategy: :one_for_one, name: ElixirClaw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp load_config do
    defaults = %{
      gateway_host: "127.0.0.1",
      gateway_port: 18789,
      node_id: "node_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)),
      display_name: "ElixirClaw Node",
      caps: [
        "camera.snap",
        "camera.clip",
        "screen.record",
        "screen.snap",
        "system.run",
        "system.notify",
        "location.get",
        "notifications.send"
      ],
      allowed_commands: []
    }

    config =
      defaults
      |> Map.merge(load_from_env())

    for {k, v} <- config do
      Application.put_env(:elixir_claw, k, v)
    end
  end

  defp load_from_env do
    env_vars = [:gateway_host, :gateway_port, :node_id, :token]
    
    Enum.reduce(env_vars, %{}, fn key, acc ->
      env_key = "ELIXIR_CLAW_" <> Atom.to_string(key) |> String.upcase()
      value = System.get_env(env_key)
      
      if value do
        parsed = 
          case key do
            :gateway_port -> String.to_integer(value)
            _ -> value
          end
        
        Map.put(acc, key, parsed)
      else
        acc
      end
    end)
  end
end
