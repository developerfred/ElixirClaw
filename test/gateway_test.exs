defmodule GatewayTest do
  use ExUnit.Case

  alias ElixirClaw.Gateway

  describe "start_link/1" do
    test "starts gateway" do
      config = %{
        node_id: "test_node",
        gateway_host: "127.0.0.1",
        gateway_port: 18789,
        display_name: "Test Node",
        caps: ["camera.snap"]
      }

      assert {:ok, pid} = Gateway.start_link(config)
      assert Process.alive?(pid)
      Process.exit(pid, :normal)
    end
  end

  describe "get_status/1" do
    test "returns error for unknown node" do
      assert Gateway.get_status("unknown") == {:error, :not_found}
    end
  end
end
