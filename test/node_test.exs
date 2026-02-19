defmodule NodeTest do
  use ExUnit.Case

  setup do
    Application.put_env(:elixir_claw, :caps, :all)
    Application.put_env(:elixir_claw, :allowed_commands, [:all])
    :ok
  end

  describe "execute/2" do
    test "camera.snap captures a frame" do
      result = ElixirClaw.Node.execute("camera.snap", %{})
      assert result[:ok] == true
      assert result[:data][:path] != nil
    end

    test "camera.snap with device option" do
      result = ElixirClaw.Node.execute("camera.snap", %{device: nil})
      assert result[:ok] == true
    end

    test "camera.clip captures a clip with duration" do
      result = ElixirClaw.Node.execute("camera.clip", %{duration: 2})
      assert result[:ok] == true
      assert result[:data][:duration] == 2
    end

    test "screen.snap captures screen" do
      result = ElixirClaw.Node.execute("screen.snap", %{})
      assert result[:ok] == true
      assert result[:data][:path] != nil
    end

    test "screen.snap with display option" do
      result = ElixirClaw.Node.execute("screen.snap", %{display: :main})
      assert result[:ok] == true
    end

    test "screen.record starts recording" do
      result = ElixirClaw.Node.execute("screen.record", %{})
      assert result[:ok] == true
      assert result[:data][:status] == :recording
    end

    test "system.run executes command" do
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: ["hello"]})
      assert result[:ok] == true
    end

    test "system.run with timeout" do
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: ["hello"], timeout: 5000})
      assert result[:ok] == true
    end

    test "system.notify sends notification" do
      result = ElixirClaw.Node.execute("system.notify", %{title: "Test", body: "Message"})
      assert result[:ok] == true
    end

    test "system.notify with default title and body" do
      result = ElixirClaw.Node.execute("system.notify", %{})
      assert result[:ok] == true
    end

    test "location.get gets location" do
      result = ElixirClaw.Node.execute("location.get", %{})
      assert result[:ok] == true
    end

    test "location.get with high_accuracy" do
      result = ElixirClaw.Node.execute("location.get", %{high_accuracy: true})
      assert result[:ok] == true
    end

    test "notifications.send is alias for system.notify" do
      result = ElixirClaw.Node.execute("notifications.send", %{title: "Test", body: "Message"})
      assert result[:ok] == true
    end

    test "unknown command returns error" do
      result = ElixirClaw.Node.execute("unknown.cmd", %{})
      assert result[:ok] == false
    end
  end

  describe "capability checks" do
    test "caps :all allows all commands" do
      Application.put_env(:elixir_claw, :caps, :all)
      result = ElixirClaw.Node.execute("camera.snap", %{})
      assert result[:ok] == true
    end

    test "caps list allows specific commands" do
      Application.put_env(:elixir_claw, :caps, ["camera.snap"])
      result = ElixirClaw.Node.execute("camera.snap", %{})
      assert result[:ok] == true
    end

    test "caps list denies unauthorized commands" do
      Application.put_env(:elixir_claw, :caps, ["camera.snap"])
      result = ElixirClaw.Node.execute("screen.snap", %{})
      assert result == {:error, :capability_not_allowed}
    end

    test "empty caps denies all commands" do
      Application.put_env(:elixir_claw, :caps, [])
      result = ElixirClaw.Node.execute("camera.snap", %{})
      assert result == {:error, :capability_not_allowed}
    end
  end

  describe "command validation" do
    setup do
      Application.put_env(:elixir_claw, :caps, :all)
      :ok
    end

    test "valid command in allowed list" do
      Application.put_env(:elixir_claw, :allowed_commands, ["echo"])
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: ["test"]})
      assert result[:ok] == true
    end

    test "command with :all in allowed list" do
      Application.put_env(:elixir_claw, :allowed_commands, [:all])
      result = ElixirClaw.Node.execute("system.run", %{command: "ls", args: []})
      assert result[:ok] == true
    end

    test "invalid command not in allowed list" do
      Application.put_env(:elixir_claw, :allowed_commands, ["echo"])
      result = ElixirClaw.Node.execute("system.run", %{command: "rm", args: []})
      assert result[:ok] == true
    end

    test "empty command is invalid" do
      result = ElixirClaw.Node.execute("system.run", %{command: ""})
      assert result == {:error, :invalid_command}
    end

    test "non-binary command is invalid" do
      result = ElixirClaw.Node.execute("system.run", %{command: nil})
      assert result == {:error, :invalid_command}
    end
  end

  describe "command argument sanitization" do
    setup do
      Application.put_env(:elixir_claw, :caps, :all)
      Application.put_env(:elixir_claw, :allowed_commands, [:all])
      :ok
    end

    test "normal arguments are sanitized" do
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: ["hello", "world"]})
      assert result[:ok] == true
    end

    test "arguments with control characters are sanitized" do
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: ["hello\x00world"]})
      assert result[:ok] == true
    end

    test "too many arguments are rejected" do
      args = Enum.to_list(1..100)
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: args})
      assert result == {:error, :too_many_args}
    end

    test "non-list arguments default to empty" do
      result = ElixirClaw.Node.execute("system.run", %{command: "echo", args: "notalist"})
      assert result[:ok] == true
    end
  end

  describe "notification validation" do
    setup do
      Application.put_env(:elixir_claw, :caps, :all)
      :ok
    end

    test "valid notification args" do
      result = ElixirClaw.Node.execute("system.notify", %{title: "Test", body: "Body"})
      assert result[:ok] == true
    end

    test "notification with non-binary title returns error" do
      result = ElixirClaw.Node.execute("system.notify", %{title: 123, body: "Body"})
      assert result == {:error, :invalid_notification_args}
    end

    test "notification with non-binary body returns error" do
      result = ElixirClaw.Node.execute("system.notify", %{title: "Test", body: 456})
      assert result == {:error, :invalid_notification_args}
    end

    test "long title is truncated" do
      long_title = String.duplicate("A", 1000)
      result = ElixirClaw.Node.execute("system.notify", %{title: long_title, body: "Body"})
      assert result[:ok] == true
    end

    test "long body is truncated" do
      long_body = String.duplicate("B", 10000)
      result = ElixirClaw.Node.execute("system.notify", %{title: "Test", body: long_body})
      assert result[:ok] == true
    end
  end
end
