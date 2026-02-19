defmodule CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "CLI commands" do
    test "help command outputs usage" do
      output = capture_io(fn -> ElixirClaw.CLI.main(["help"]) end)
      assert output =~ "Usage:"
      assert output =~ "elixir_claw"
    end

    test "--help flag outputs usage" do
      output = capture_io(fn -> ElixirClaw.CLI.main(["--help"]) end)
      assert output =~ "Usage:"
      assert output =~ "elixir_claw"
    end

    test "unknown command outputs error" do
      output = capture_io(:stderr, fn -> ElixirClaw.CLI.main(["unknown-cmd"]) end)
      assert output =~ "Error: Unknown command"
    end

    test "status command outputs status" do
      Application.put_env(:elixir_claw, :node_id, "test-node")
      Application.put_env(:elixir_claw, :display_name, "Test Node")
      Application.put_env(:elixir_claw, :gateway_host, "localhost")
      Application.put_env(:elixir_claw, :gateway_port, 18789)
      Application.put_env(:elixir_claw, :caps, ["camera.snap", "screen.snap"])
      
      output = capture_io(fn -> ElixirClaw.CLI.main(["status"]) end)
      assert output =~ "ElixirClaw Status"
      assert output =~ "Node ID: test-node"
      assert output =~ "Test Node"
    end

    test "approvals command outputs approvals list" do
      output = capture_io(fn -> ElixirClaw.CLI.main(["approvals"]) end)
      assert output =~ "Pending Approvals"
    end

    test "config command outputs config" do
      Application.put_env(:elixir_claw, :test_key, "test_value")
      
      output = capture_io(fn -> ElixirClaw.CLI.main(["config"]) end)
      assert output =~ "test_key"
    end

    test "approve command outputs approval message" do
      output = capture_io(fn -> ElixirClaw.CLI.main(["approve", "test-id"]) end)
      assert output =~ "Approving: test-id"
    end

    test "reject command outputs rejection message" do
      output = capture_io(fn -> ElixirClaw.CLI.main(["reject", "test-id"]) end)
      assert output =~ "Rejecting: test-id"
    end
  end
end
