defmodule ElixirClaw.Gateway.Supervisor do
  @moduledoc """
  Supervisor for Gateway connections.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 10)
  end

  def start_gateway(config) do
    spec = {ElixirClaw.Gateway, config}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_gateway(node_id) do
    case Registry.lookup(ElixirClaw.Registry, {:gateway, node_id}) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end

  def list_gateways do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
