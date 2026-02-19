defmodule ProtocolTest do
  use ExUnit.Case

  describe "encode_request" do
    test "generates valid JSON request" do
      result = ElixirClaw.Protocol.encode_request("test.method", %{"key" => "value"})
      assert is_binary(result)
      
      {:ok, decoded} = Jason.decode(result)
      assert decoded["type"] == "req"
      assert decoded["method"] == "test.method"
      assert decoded["params"] == %{"key" => "value"}
      assert decoded["id"] != nil
    end

    test "uses custom request id when provided" do
      result = ElixirClaw.Protocol.encode_request("test", %{}, "custom-id")
      {:ok, decoded} = Jason.decode(result)
      assert decoded["id"] == "custom-id"
    end
  end

  describe "decode" do
    test "decodes request message" do
      msg = ~s({"type":"req","id":"abc","method":"test.method","params":{}})
      {:ok, result} = ElixirClaw.Protocol.decode(msg)
      
      assert result.type == :req
      assert result.id == "abc"
      assert result.method == "test.method"
    end

    test "decodes response message" do
      msg = ~s({"type":"res","id":"abc","ok":true,"payload":{}})
      {:ok, result} = ElixirClaw.Protocol.decode(msg)
      
      assert result.type == :res
      assert result.ok == true
    end

    test "decodes event message" do
      msg = ~s({"type":"event","event":"test.event","payload":{"data":1}})
      {:ok, result} = ElixirClaw.Protocol.decode(msg)
      
      assert result.type == :event
      assert result.event == "test.event"
      assert result.payload == %{"data" => 1}
    end
  end

  describe "generate_request_id" do
    test "generates unique IDs" do
      ids = Enum.map(1..100, fn _ -> ElixirClaw.Protocol.generate_request_id() end)
      assert ids |> Enum.uniq() |> length() == 100
    end

    test "generates lowercase hex strings" do
      id = ElixirClaw.Protocol.generate_request_id()
      assert Regex.match?(~r/^[a-f0-9]+$/, id)
    end
  end
end
