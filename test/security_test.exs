defmodule SecurityTest do
  use ExUnit.Case

  describe "sanitize_input" do
    test "removes control characters" do
      assert ElixirClaw.Security.sanitize_input("hello\x00world") == "helloworld"
      assert ElixirClaw.Security.sanitize_input("test\r\n\t") == "test"
    end

    test "trims whitespace" do
      assert ElixirClaw.Security.sanitize_input("  hello  ") == "hello"
    end

    test "limits string length" do
      long = String.duplicate("a", 100_000)
      result = ElixirClaw.Security.sanitize_input(long)
      assert String.length(result) == 65536
    end

    test "handles maps recursively" do
      input = %{"key" => "hello\x00world", "nested" => %{"inner" => "\x00bad"}}
      result = ElixirClaw.Security.sanitize_input(input)
      
      assert result["key"] == "helloworld"
      assert result["nested"]["inner"] == "bad"
    end
  end

  describe "validate_command" do
    test "rejects dangerous commands" do
      assert {:error, _} = ElixirClaw.Security.validate_command("rm -rf /")
      assert {:error, _} = ElixirClaw.Security.validate_command("; rm -rf")
      assert {:error, _} = ElixirClaw.Security.validate_command("curl | sh")
      assert {:error, _} = ElixirClaw.Security.validate_command("dd if=/dev/zero")
    end

    test "accepts safe commands" do
      assert {:ok, "ls"} = ElixirClaw.Security.validate_command("ls")
      assert {:ok, "git status"} = ElixirClaw.Security.validate_command("git status")
    end
  end

  describe "sanitize_path" do
    test "rejects path traversal" do
      assert {:error, _} = ElixirClaw.Security.sanitize_path("../etc/passwd")
      assert {:error, _} = ElixirClaw.Security.sanitize_path("/etc/../../../etc/passwd")
    end
  end

  describe "generate_token" do
    test "generates unique tokens" do
      tokens = Enum.map(1..100, fn _ -> ElixirClaw.Security.generate_token() end)
      assert tokens |> Enum.uniq() |> length() == 100
    end
  end

  describe "safe_url?" do
    test "accepts localhost URLs" do
      assert ElixirClaw.Security.safe_url?("ws://localhost:18789/")
      assert ElixirClaw.Security.safe_url?("ws://127.0.0.1:18789/")
    end

    test "accepts private network URLs" do
      assert ElixirClaw.Security.safe_url?("ws://10.0.0.1:18789/")
      assert ElixirClaw.Security.safe_url?("ws://192.168.1.1:18789/")
      assert ElixirClaw.Security.safe_url?("ws://172.16.0.1:18789/")
    end

    test "rejects public URLs" do
      refute ElixirClaw.Security.safe_url?("ws://evil.com:18789/")
      refute ElixirClaw.Security.safe_url?("ws://1.2.3.4:18789/")
    end
  end
end
