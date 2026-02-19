defmodule ElixirClaw.Telemetry.ConsoleReporter do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many(
      "console-reporter",
      [
        [:elixir_claw, :gateway, :connect, :stop],
        [:elixir_claw, :gateway, :message, :receive],
        [:elixir_claw, :node, :invoke, :stop]
      ],
      &handle_event/4,
      :nothing
    )

    {:ok, %{}}
  end

  defp handle_event(event, measurements, _metadata, _config) do
    IO.puts("[Telemetry] #{inspect(event)}: #{inspect(measurements)}")
  end
end
