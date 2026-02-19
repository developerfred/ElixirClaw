defmodule ConfigProviderTest do
  use ExUnit.Case

  describe "ElixirClaw.Config.Provider" do
    test "init returns config list" do
      result = ElixirClaw.Config.Provider.init([elixir_claw: [node_id: "test"]])
      assert result == [elixir_claw: [node_id: "test"]]
    end

    test "load merges defaults when no file exists" do
      result = ElixirClaw.Config.Provider.load([], "/nonexistent/path.json")
      
      assert {:elixir_claw, config} = List.keyfind(result, :elixir_claw, 0)
      assert is_list(config)
    end

    test "load applies environment variables" do
      System.put_env("ELIXIR_CLAW_HOST", "custom.host.com")
      System.put_env("ELIXIR_CLAW_PORT", "9999")
      
      result = ElixirClaw.Config.Provider.load([], nil)
      {:elixir_claw, config} = List.keyfind(result, :elixir_claw, 0)
      
      host = Keyword.get(config, :gateway_host)
      port = Keyword.get(config, :gateway_port)
      
      assert host == "custom.host.com"
      assert port == 9999
      
      System.delete_env("ELIXIR_CLAW_HOST")
      System.delete_env("ELIXIR_CLAW_PORT")
    end

    test "load reads from config file" do
      System.put_env("ELIXIR_CLAW_HOST", "file.host.com")
      System.put_env("ELIXIR_CLAW_PORT", "19999")
      
      config_json = Jason.encode!(%{
        "gateway_host" => "file.host.com",
        "gateway_port" => 19999,
        "node_id" => "file-node-id"
      })
      
      path = Path.join(System.tmp_dir!(), "elixir_claw_test_config_#{:os.system_time(:millisecond)}.json")
      File.write!(path, config_json)
      
      result = ElixirClaw.Config.Provider.load([], path)
      {:elixir_claw, config} = List.keyfind(result, :elixir_claw, 0)
      
      assert Keyword.get(config, :gateway_host) == "file.host.com"
      assert Keyword.get(config, :gateway_port) == 19999
      
      File.rm!(path)
      System.delete_env("ELIXIR_CLAW_HOST")
      System.delete_env("ELIXIR_CLAW_PORT")
    end

    test "load handles invalid JSON gracefully" do
      path = Path.join(System.tmp_dir!(), "elixir_claw_test_invalid_#{:os.system_time(:millisecond)}.json")
      File.write!(path, "not valid json")
      
      result = ElixirClaw.Config.Provider.load([], path)
      {:elixir_claw, config} = List.keyfind(result, :elixir_claw, 0)
      
      assert is_list(config)
      
      File.rm!(path)
    end
  end
end
