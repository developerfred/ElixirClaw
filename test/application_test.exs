defmodule ApplicationTest do
  use ExUnit.Case

  describe "start/2" do
    test "application starts without errors" do
      Process.register(self(), :test_app)
      result = ElixirClaw.Application.start(:normal, [])
      assert is_tuple(result)
    end
  end
end
