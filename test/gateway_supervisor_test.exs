defmodule GatewaySupervisorTest do
  use ExUnit.Case

  # ElixirClaw.Gateway.Supervisor is already started by the application,
  # so these tests exercise the running instance instead of starting a new one.

  defp gateway_config(node_id) do
    %{node_id: node_id, gateway_host: "127.0.0.1", gateway_port: 18789}
  end

  describe "ElixirClaw.Gateway.Supervisor" do
    test "is started by the application" do
      assert is_pid(Process.whereis(ElixirClaw.Gateway.Supervisor))
    end

    test "start_link refuses a second instance" do
      assert {:error, {:already_started, _pid}} = ElixirClaw.Gateway.Supervisor.start_link([])
    end

    test "start_gateway starts a gateway child" do
      node_id = "test-node-#{System.unique_integer([:positive])}"

      assert {:ok, child} = ElixirClaw.Gateway.Supervisor.start_gateway(gateway_config(node_id))
      assert is_pid(child)

      on_exit(fn -> ElixirClaw.Gateway.Supervisor.stop_gateway(node_id) end)
    end

    test "stop_gateway terminates a gateway" do
      node_id = "test-node-stop-#{System.unique_integer([:positive])}"

      assert {:ok, _child} = ElixirClaw.Gateway.Supervisor.start_gateway(gateway_config(node_id))

      assert :ok = ElixirClaw.Gateway.Supervisor.stop_gateway(node_id)
      assert {:error, :not_found} = ElixirClaw.Gateway.Supervisor.stop_gateway(node_id)
    end

    test "stop_gateway returns error for unknown node" do
      assert {:error, :not_found} = ElixirClaw.Gateway.Supervisor.stop_gateway("nonexistent-node")
    end

    test "list_gateways returns child processes" do
      assert is_list(ElixirClaw.Gateway.Supervisor.list_gateways())
    end
  end
end
