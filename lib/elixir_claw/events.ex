defmodule ElixirClaw.Events do
  @moduledoc """
  Event streaming system for capability execution progress.

  Provides real-time feedback during long-running operations like:
  - screen.record
  - camera.clip
  - system.run

  Events are broadcast via Elixir's Registry and can be consumed by:
  - Phoenix LiveView dashboard
  - WebSocket clients
  - Telemetry handlers
  - Log aggregators
  """

  @registry ElixirClaw.Registry

  @type event_type ::
          :capability_started
          | :capability_progress
          | :capability_completed
          | :capability_failed

  @type event :: %{
          type: event_type(),
          capability: String.t(),
          node_id: String.t(),
          request_id: String.t(),
          timestamp: integer(),
          data: map(),
          metadata: map()
        }

  @doc """
  Subscribe to events for a specific node or all nodes.
  """
  def subscribe(node_id \\ nil) do
    if node_id do
      Registry.register(@registry, {:events, node_id}, [])
    else
      Registry.register(@registry, :events_all, [])
    end
  end

  @doc """
  Unsubscribe from events.
  """
  def unsubscribe(node_id \\ nil) do
    if node_id do
      Registry.unregister(@registry, {:events, node_id})
    else
      Registry.unregister(@registry, :events_all)
    end
  end

  @doc """
  Emit a capability started event.
  """
  def emit_started(capability, node_id, request_id, metadata \\ %{}) do
    emit(%{
      type: :capability_started,
      capability: capability,
      node_id: node_id,
      request_id: request_id,
      timestamp: :os.system_time(:millisecond),
      data: %{},
      metadata: metadata
    })
  end

  @doc """
  Emit a capability progress event.
  """
  def emit_progress(capability, node_id, request_id, progress_data, metadata \\ %{}) do
    emit(%{
      type: :capability_progress,
      capability: capability,
      node_id: node_id,
      request_id: request_id,
      timestamp: :os.system_time(:millisecond),
      data: progress_data,
      metadata: metadata
    })
  end

  @doc """
  Emit a capability completed event.
  """
  def emit_completed(capability, node_id, request_id, result_data, metadata \\ %{}) do
    emit(%{
      type: :capability_completed,
      capability: capability,
      node_id: node_id,
      request_id: request_id,
      timestamp: :os.system_time(:millisecond),
      data: result_data,
      metadata: metadata
    })
  end

  @doc """
  Emit a capability failed event.
  """
  def emit_failed(capability, node_id, request_id, error_data, metadata \\ %{}) do
    emit(%{
      type: :capability_failed,
      capability: capability,
      node_id: node_id,
      request_id: request_id,
      timestamp: :os.system_time(:millisecond),
      data: error_data,
      metadata: metadata
    })
  end

  @doc """
  Emit an event to all subscribers.
  """
  def emit(event) do
    :telemetry.execute(
      [:elixir_claw, :event, event.type],
      %{count: 1},
      Map.take(event, [:capability, :node_id, :request_id])
    )

    Registry.dispatch(@registry, {:events, event.node_id}, fn entries ->
      for {pid, _} <- entries do
        send(pid, {:elixir_claw_event, event})
      end
    end)

    Registry.dispatch(@registry, :events_all, fn entries ->
      for {pid, _} <- entries do
        send(pid, {:elixir_claw_event, event})
      end
    end)

    :ok
  end

  @doc """
  Get event history for a node (stub for future persistence).
  """
  def get_history(_node_id, _opts \\ []) do
    []
  end

  @doc """
  Stream events for a capability execution.
  Returns a stream that yields progress events until completion.
  """
  def stream_events(_capability, node_id, request_id, opts \\ []) do
    timeout = opts[:timeout] || 60_000

    Stream.resource(
      fn ->
        subscribe(node_id)
        {node_id, request_id, timeout, :os.system_time(:millisecond)}
      end,
      fn {node_id, request_id, timeout, start_time} ->
        elapsed = :os.system_time(:millisecond) - start_time

        if elapsed > timeout do
          {:halt, {node_id, request_id, timeout, start_time}}
        else
          receive do
            {:elixir_claw_event, event} when event.request_id == request_id ->
              case event.type do
                :capability_completed ->
                  {[event], {:done, event}}

                :capability_failed ->
                  {[event], {:done, event}}

                _ ->
                  {[event], {node_id, request_id, timeout, start_time}}
              end
          after
            1000 ->
              {[], {node_id, request_id, timeout, start_time}}
          end
        end
      end,
      fn
        {:done, _} -> :ok
        {node_id, _, _, _} -> unsubscribe(node_id)
      end
    )
  end
end
