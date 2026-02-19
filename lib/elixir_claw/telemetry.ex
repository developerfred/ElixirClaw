defmodule ElixirClaw.Telemetry do
  @moduledoc """
  Telemetry instrumentation for ElixirClaw.
  """

  require Logger

  def execute(event, measurements, metadata, _config) do
    node_id =
      metadata[:node_id] || metadata[:device_id] || metadata["node_id"] || metadata["device_id"]

    command = metadata[:command] || metadata[:method] || metadata["command"] || metadata["method"]

    Logger.debug("Telemetry: #{event}",
      node_id: node_id,
      command: command,
      event: List.last(event),
      measurements: measurements,
      metadata:
        Map.drop(metadata, [:node_id, :device_id, :command, :method, :module, :function, :line])
    )
  end

  def attach_handlers do
    :telemetry.attach(
      "elixir_claw-handler",
      [:elixir_claw, :gateway, :connect],
      &__MODULE__.execute/4,
      %{}
    )

    :telemetry.attach(
      "elixir_claw-message-handler",
      [:elixir_claw, :gateway, :message],
      &__MODULE__.execute/4,
      %{}
    )

    :telemetry.attach(
      "elixir_claw-invoke-handler",
      [:elixir_claw, :node, :invoke],
      &__MODULE__.execute/4,
      %{}
    )
  end
end
