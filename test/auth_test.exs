defmodule AuthTest do
  use ExUnit.Case

  describe "generate_identity/0" do
    test "generates identity with device_id" do
      identity = ElixirClaw.Auth.generate_identity()
      assert is_binary(identity.device_id)
      assert String.starts_with?(identity.device_id, "device_")
    end

    test "generates different identities" do
      ids = Enum.map(1..10, fn _ -> ElixirClaw.Auth.generate_identity().device_id end)
      assert length(Enum.uniq(ids)) == 10
    end

    test "generates identity with keys" do
      identity = ElixirClaw.Auth.generate_identity()
      assert is_binary(identity.public_key)
      assert is_binary(identity.private_key)
    end
  end

  describe "load_identity/1" do
    test "loads identity from valid file" do
      identity = ElixirClaw.Auth.generate_identity()
      path = Path.join(System.tmp_dir!(), "elixir_claw_test_identity_#{:os.system_time(:millisecond)}.json")
      
      ElixirClaw.Auth.save_identity(identity, path)
      {:ok, loaded} = ElixirClaw.Auth.load_identity(path)
      
      assert loaded.device_id == identity.device_id
      assert loaded.public_key == identity.public_key
      
      File.rm!(path)
    end

    test "returns error for non-existent file" do
      result = ElixirClaw.Auth.load_identity("/nonexistent/path/identity.json")
      assert result == {:error, :enoent}
    end

    test "returns error for invalid JSON" do
      path = Path.join(System.tmp_dir!(), "elixir_claw_test_invalid_#{:os.system_time(:millisecond)}.json")
      File.write!(path, "not valid json")
      
      result = ElixirClaw.Auth.load_identity(path)
      assert match?({:error, _}, result)
      
      File.rm!(path)
    end
  end

  describe "save_identity/2" do
    test "saves identity to file" do
      identity = ElixirClaw.Auth.generate_identity()
      path = Path.join(System.tmp_dir!(), "elixir_claw_test_save_#{:os.system_time(:millisecond)}.json")
      
      result = ElixirClaw.Auth.save_identity(identity, path)
      assert result == :ok
      assert File.exists?(path)
      
      File.rm!(path)
    end

    test "creates directory if not exists" do
      identity = ElixirClaw.Auth.generate_identity()
      dir = Path.join(System.tmp_dir!(), "elixir_claw_test_#{:os.system_time(:millisecond)}")
      path = Path.join(dir, "identity.json")
      
      ElixirClaw.Auth.save_identity(identity, path)
      assert File.exists?(dir)
      
      File.rm_rf!(dir)
    end
  end

  describe "sign_challenge/2" do
    # Ed25519 signing requires specific key format - tested via integration
  end

  describe "verify_signature/3" do
    test "rejects invalid base64 signature" do
      identity = ElixirClaw.Auth.generate_identity()
      challenge = "test_challenge"
      # Invalid base64 (contains underscore)
      assert catch_error(ElixirClaw.Auth.verify_signature(identity, challenge, "invalid_signature")) != nil
    end
  end
end
