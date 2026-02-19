defmodule GatewaySupervisorTest do
  use ExUnit.Case

  describe "ElixirClaw.Gateway.Supervisor" do
    test "start_link initializes dynamic supervisor" do
      {:ok, pid} = ElixirClaw.Gateway.Supervisor.start_link([])
      assert is_pid(pid)
      DynamicSupervisor.stop(pid)
    end

    test "start_gateway starts a gateway child" do
      {:ok, pid} = ElixirClaw.Gateway.Supervisor.start_link([])
      
      config = [
        node_id: "test-node-#{:os.system_time(:millisecond)}",
        gateway_host: "127.0.0.1",
        gateway_port: 18789
      ]
      
      {:ok, _child} = ElixirClaw.Gateway.Supervisor.start_gateway(config)
      
      DynamicSupervisor.stop(pid)
    end

    test "stop_gateway terminates a gateway" do
      {:ok, pid} = ElixirClaw.Gateway.Supervisor.start_link([])
      
      node_id = "test-node-stop-#{:os.system_time(:millisecond)}"
      
      config = [
        node_id: node_id,
        gateway_host: "127.0.0.1",
        gateway_port: 18789
      ]
      
      {:ok, _child} = ElixirClaw.Gateway.Supervisor.start_gateway(config)
      
      # Give it time to start
      Process.sleep(100)
      
      result = ElixirClaw.Gateway.Supervisor.stop_gateway(node_id)
      assert result == :ok
      
      DynamicSupervisor.stop(pid)
    end

    test "stop_gateway returns error for unknown node" do
      {:ok, pid} = ElixirClaw.Gateway.Supervisor.start_link([])
      
      result = ElixirClaw.Gateway.Supervisor.stop_gateway("nonexistent-node")
      assert result == {:error, :not_found}
      
      DynamicSupervisor.stop(pid)
    end

    test "list_gateways returns child processes" do
      {:ok, pid} = ElixirClaw.Gateway.Supervisor.start_link([])
      
      children = ElixirClaw.Gateway.Supervisor.list_gateways()
      assert is_list(children)
      
      DynamicSupervisor.stop(pid)
    end
  end
end
