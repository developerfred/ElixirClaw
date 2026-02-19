defmodule ElixirClaw.Protocol do
  @moduledoc """
  OpenClaw Gateway Protocol encoding and decoding.
  Handles JSON message framing, request/response correlation, and event parsing.
  """

  alias __MODULE__

  @protocol_version 3

  @type message_type :: :req | :res | :event
  @type method :: binary()
  @type request_id :: binary()
  @type payload :: map()

  defstruct [:type, :id, :method, :payload, :event, :ok, :error]

  @doc """
  Encode a request message to JSON binary.
  """
  def encode_request(method, params, request_id \\ nil) do
    id = request_id || generate_request_id()

    message = %{
      "type" => "req",
      "id" => id,
      "method" => method,
      "params" => params
    }

    Jason.encode!(message)
  end

  @doc """
  Encode an event message to JSON binary.
  """
  def encode_event(event, payload) do
    message = %{
      "type" => "event",
      "event" => event,
      "payload" => payload
    }

    Jason.encode!(message)
  end

  @doc """
  Decode a JSON binary message to Protocol struct.
  """
  def decode(message) when is_binary(message) do
    case Jason.decode(message) do
      {:ok, map} -> decode_map(map)
      error -> error
    end
  end

  defp decode_map(%{"type" => "req"} = map) do
    {:ok,
     %Protocol{
       type: :req,
       id: map["id"],
       method: map["method"],
       payload: map["params"] || %{}
     }}
  end

  defp decode_map(%{"type" => "res"} = map) do
    {:ok,
     %Protocol{
       type: :res,
       id: map["id"],
       ok: map["ok"],
       payload: map["payload"] || map["error"] || %{}
     }}
  end

  defp decode_map(%{"type" => "event"} = map) do
    {:ok,
     %Protocol{
       type: :event,
       event: map["event"],
       payload: map["payload"] || %{}
     }}
  end

  defp decode_map(map) do
    {:error, {:invalid_message, map}}
  end

  @doc """
  Build a connect request with proper authentication.
  """
  def build_connect_request(config, challenge) do
    timestamp = :os.system_time(:millisecond)

    device = if config[:device_id] do
      %{
        "id" => config.device_id,
        "publicKey" => config.public_key || "",
        "signature" => sign_challenge(config, challenge, timestamp),
        "signedAt" => timestamp,
        "nonce" => challenge["nonce"]
      }
    else
      %{}
    end

    params = %{
      "minProtocol" => @protocol_version,
      "maxProtocol" => @protocol_version,
      "client" => %{
        "id" => config.client_id || "elixir_claw",
        "version" => "0.1.0",
        "platform" => :os.type() |> elem(0) |> Atom.to_string(),
        "mode" => "node"
      },
      "role" => "node",
      "scopes" => config.scopes || node_scopes(),
      "caps" => config.caps || default_caps(),
      "commands" => config.commands || [],
      "permissions" => config.permissions || %{},
      "auth" => build_auth(config),
      "locale" => "en-US",
      "userAgent" => "ElixirClaw/0.1.0",
      "device" => device
    }

    encode_request("connect", params)
  end

  @doc """
  Build node.describe response with capabilities.
  """
  def build_node_describe(config) do
    %{
      "nodeId" => config.node_id,
      "displayName" => config.display_name || "ElixirClaw Node",
      "device" => %{
        "model" => get_device_model(),
        "platform" => get_platform(),
        "osVersion" => get_os_version()
      },
      "caps" => config.caps || default_caps(),
      "state" => %{}
    }
  end

  @doc """
  Generate unique request ID.
  """
  def generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  @doc """
  Extract request ID from a response or event for correlation.
  """
  def get_request_id(%Protocol{id: id}), do: id
  def get_request_id(_), do: nil

  defp node_scopes do
    [
      "node.read",
      "node.write",
      "node.invoke",
      "operator.read"
    ]
  end

  defp default_caps do
    [
      "camera.snap",
      "camera.clip",
      "screen.record",
      "screen.snap",
      "system.run",
      "system.notify",
      "location.get",
      "notifications.send"
    ]
  end

  defp build_auth(%{token: token}) when token != nil do
    %{"token" => token}
  end

  defp build_auth(_config) do
    %{}
  end

  defp sign_challenge(config, challenge, timestamp) do
    message = "#{challenge["nonce"]}#{timestamp}"
    # For now, return a placeholder. Real implementation would use Ed25519
    Base.encode16(:crypto.hash(:sha256, message))
  end

  defp get_device_model do
    case :os.type() do
      {:unix, :darwin} -> "Mac"
      {:unix, :linux} -> "Linux"
      {:win32, :nt} -> "Windows"
      _ -> "Unknown"
    end
  end

  defp get_platform do
    case :os.type() do
      {:unix, :darwin} -> "macos"
      {:unix, :linux} -> "linux"
      {:win32, :nt} -> "windows"
      _ -> "unknown"
    end
  end

  defp get_os_version do
    :os.version() |> Tuple.to_list() |> Enum.join(".")
  end
end
