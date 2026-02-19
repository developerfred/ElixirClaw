defmodule ElixirClaw do
  @moduledoc """
  ElixirClaw - OpenClaw Node implemented in Elixir.

  A high-performance, secure node client for OpenClaw Gateway.
  """

  @doc """
  Start the ElixirClaw application.
  """
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ElixirClaw.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: ElixirClaw.Gateway.Supervisor},
      ElixirClaw.Config.Provider
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ElixirClaw.Supervisor)
  end
end
