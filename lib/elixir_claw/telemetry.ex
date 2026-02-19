defmodule ElixirClaw.Telemetry do
  @moduledoc """
  Telemetry instrumentation for ElixirClaw.
  """

  require Logger

  def execute(event, measurements, metadata, config) do
    Logger.debug("Telemetry: #{event}", metadata: metadata)
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
