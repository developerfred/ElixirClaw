defmodule ElixirClaw.Gateway do
  @moduledoc """
  WebSocket client for OpenClaw Gateway.
  Handles connection lifecycle, reconnection, heartbeats, and message routing.
  """

  use GenServer
  require Logger

  alias ElixirClaw.{Protocol, Node}

  @default_gateway_host "127.0.0.1"
  @default_gateway_port 18789
  @default_tick_interval 15000
  @max_reconnect_attempts 10
  @reconnect_base_delay 1000

  defstruct [
    :gateway_host,
    :gateway_port,
    :config,
    :conn,
    :websocket,
    :state,
    :request_buffer,
    :reconnect_attempts,
    :last_heartbeat,
    :tick_interval
  ]

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: via_tuple(config.node_id))
  end

  def via_tuple(node_id) do
    {:via, Registry, {ElixirClaw.Registry, {:gateway, node_id}}}
  end

  @impl true
  def init(config) do
    state = %__MODULE__{
      gateway_host: config[:gateway_host] || @default_gateway_host,
      gateway_port: config[:gateway_port] || @default_gateway_port,
      config: config,
      request_buffer: %{},
      reconnect_attempts: 0,
      tick_interval: @default_tick_interval,
      state: :disconnected
    }

    Logger.info("ElixirClaw Gateway starting - #{state.gateway_host}:#{state.gateway_port}")

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    case connect(state) do
      {:ok, new_state} ->
        {:noreply, new_state}

      error ->
        Logger.error("Failed to connect: #{inspect(error)}")
        {:stop, :connection_failed, state}
    end
  end

  defp connect(state) do
    uri = if String.starts_with?(state.gateway_host, "wss://") do
      state.gateway_host
    else
      "ws://#{state.gateway_host}:#{state.gateway_port}"
    end
    
    parsed_uri = URI.parse(uri)

    http_scheme = case parsed_uri.scheme do
      "ws" -> :http
      "wss" -> :https
      _ -> :http
    end

    ws_scheme = case parsed_uri.scheme do
      "ws" -> :ws
      "wss" -> :wss
      _ -> :ws
    end

    transport = if http_scheme == :https do
      :ssl
    else
      :tcp
    end

    path = parsed_uri.path || "/"

    opts = [
      transport: transport,
      timeout: 10_000
    ]

    case Mint.HTTP.connect(http_scheme, parsed_uri.host, parsed_uri.port, opts) do
      {:ok, conn} ->
        case Mint.WebSocket.upgrade(ws_scheme, conn, path, []) do
          {:ok, conn, ref} ->
            http_response = receive do
              {:tcp, _port, data} -> {:ok, data}
              {:ssl, _port, data} -> {:ok, data}
              after 10_000 -> {:error, :timeout}
            end

            case http_response do
              {:ok, data} ->
                case Mint.WebSocket.stream(conn, data) do
                  {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, headers}, {:done, ^ref}]} ->
                    {:ok, websocket} = Mint.WebSocket.new(conn, ref, status, headers)
                    new_state = %{state | conn: conn, websocket: websocket, state: :connected}
                    Logger.info("WebSocket connected to #{parsed_uri.host}:#{parsed_uri.port}")
                    {:ok, new_state}

                  error ->
                    Logger.error("WebSocket stream error: #{inspect(error)}")
                    Mint.HTTP.close(conn)
                    {:error, :stream_failed}
                end

              {:error, reason} ->
                Logger.error("WebSocket upgrade response error: #{inspect(reason)}")
                Mint.HTTP.close(conn)
                {:error, reason}
            end

          {:error, conn, reason} ->
            Logger.error("WebSocket upgrade error: #{inspect(reason)}")
            Mint.HTTP.close(conn)
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("HTTP connect error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def handle_info(:heartbeat, %{state: :connected} = state) do
    message = Protocol.encode_request("heartbeat", %{}, Protocol.generate_request_id())
    send_text(state, message)

    new_state = %{state | last_heartbeat: :os.system_time(:millisecond)}
    schedule_heartbeat(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, _port, data}, state) do
    process_data(data, state)
  end

  @impl true
  def handle_info({:ssl, _port, data}, state) do
    process_data(data, state)
  end

  @impl true
  def handle_info({:tcp_closed, _port}, state) do
    Logger.warning("Gateway connection closed")
    handle_disconnect(state)
  end

  @impl true
  def handle_info({:ssl_closed, _port}, state) do
    Logger.warning("Gateway SSL connection closed")
    handle_disconnect(state)
  end

  @impl true
  def handle_info({:reconnect}, state) do
    if state.reconnect_attempts < @max_reconnect_attempts do
      delay = :math.pow(2, state.reconnect_attempts) * @reconnect_base_delay
      |> round
      |> min(30000)

      Logger.info("Reconnecting in #{delay}ms (attempt #{state.reconnect_attempts + 1})")

      Process.send_after(self(), {:reconnect}, delay)

      new_state = %{state | reconnect_attempts: state.reconnect_attempts + 1}
      {:noreply, new_state}
    else
      Logger.error("Max reconnection attempts reached")
      {:stop, :max_reconnect_attempts, state}
    end
  end

  defp process_data(data, state) do
    case Mint.WebSocket.stream(state.conn, data) do
      {:ok, conn, messages} ->
        new_state = %{state | conn: conn}

        Enum.reduce(messages, new_state, fn msg, acc ->
          handle_stream_message(msg, acc)
        end)
        |> then(&{:noreply, &1})

      {:error, conn, reason, _rest} ->
        Logger.error("WebSocket stream error: #{inspect(reason)}")
        {:noreply, %{state | conn: conn}}

      :unknown ->
        {:noreply, state}
    end
  end

  defp handle_stream_message({:text, message}, state) do
    case Protocol.decode(message) do
      {:ok, protocol} ->
        handle_protocol_message(protocol, state)

      error ->
        Logger.warning("Failed to decode message: #{inspect(error)}")
        state
    end
  end

  defp handle_stream_message({:ping, payload}, state) do
    case Mint.WebSocket.encode(state.websocket, {:pong, payload}) do
      {:ok, websocket, data} ->
        Mint.HTTP.send(state.conn, data)
        %{state | websocket: websocket}

      {:error, websocket, _reason} ->
        %{state | websocket: websocket}
    end
  end

  defp handle_stream_message(:pong, state) do
    state
  end

  defp handle_stream_message({:close, code, reason}, state) do
    Logger.info("WebSocket close: #{code} - #{reason}")
    handle_disconnect(state)
  end

  defp handle_stream_message(message, state) do
    Logger.debug("Unhandled stream message: #{inspect(message)}")
    state
  end

  defp handle_protocol_message(%Protocol{type: :event, event: "connect.challenge"} = msg, state) do
    Logger.debug("Received connect challenge")
    connect_request = Protocol.build_connect_request(state.config, msg.payload)
    send_text(state, connect_request)
    state
  end

  defp handle_protocol_message(%Protocol{type: :res, method: "connect", ok: true} = msg, state) do
    Logger.info("Connected successfully to Gateway")
    new_state = %{state | state: :authenticated, reconnect_attempts: 0}
    schedule_heartbeat(new_state)

    describe = Protocol.build_node_describe(state.config)
    describe_request = Protocol.encode_request("node.describe", describe, Protocol.generate_request_id())
    send_text(new_state, describe_request)

    new_state
  end

  defp handle_protocol_message(%Protocol{type: :req, method: "node.invoke"} = msg, state) do
    Task.Supervisor.async_nolink(ElixirClaw.TaskSupervisor, fn ->
      handle_node_invoke(msg.payload, state)
    end)
    state
  end

  defp handle_protocol_message(%Protocol{type: :event, event: "exec.approval_required"} = msg, state) do
    Logger.info("Approval required: #{inspect(msg.payload)}")
    broadcast_approval_request(msg.payload)
    state
  end

  defp handle_protocol_message(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    state
  end

  defp handle_node_invoke(payload, state) do
    command = payload["command"]
    args = payload["args"] || %{}

    result = Node.execute(command, args)

    response = %{
      "id" => payload["id"],
      "ok" => result[:ok],
      "result" => result[:data] || %{},
      "error" => result[:error]
    }

    response_msg = Protocol.encode_request("node.invoke.res", response, payload["id"])
    send_text(state, response_msg)
  end

  defp send_text(state, message) do
    case Mint.WebSocket.encode(state.websocket, {:text, message}) do
      {:ok, websocket, data} ->
        Mint.HTTP.send(state.conn, data)
        %{state | websocket: websocket}

      {:error, websocket, reason} ->
        Logger.error("WebSocket encode error: #{inspect(reason)}")
        %{state | websocket: websocket}
    end
  end

  defp handle_disconnect(state) do
    new_state = %{state | state: :disconnected, conn: nil, websocket: nil}
    Process.send(self(), {:reconnect}, [])
    new_state
  end

  defp schedule_heartbeat(state) do
    Process.send_after(self(), :heartbeat, state.tick_interval)
  end

  defp broadcast_approval_request(payload) do
    Registry.dispatch(ElixirClaw.Registry, :approvals, fn entries ->
      for {pid, _} <- entries do
        send(pid, {:approval_request, payload})
      end
    end)
  end

  def send_message(node_id, message) do
    case Registry.lookup(ElixirClaw.Registry, {:gateway, node_id}) do
      [{pid, _}] -> GenServer.cast(pid, {:send, message})
      [] -> {:error, :not_found}
    end
  end

  def get_status(node_id) do
    case Registry.lookup(ElixirClaw.Registry, {:gateway, node_id}) do
      [{pid, _}] -> GenServer.call(pid, :get_status)
      [] -> {:error, :not_found}
    end
  end
end
