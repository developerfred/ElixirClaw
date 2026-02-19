defmodule ElixirClawTest do
  use ExUnit.Case

  describe "Protocol.generate_request_id/0" do
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
