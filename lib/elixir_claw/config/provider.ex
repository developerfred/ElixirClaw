defmodule ElixirClaw.Config.Provider do
  @moduledoc """
  Configuration provider for ElixirClaw.
  Implements Config.Provider behaviour to load configuration at runtime.
  """
  require Logger

  @behaviour Config.Provider

  @impl Config.Provider
  def init(config) when is_list(config) do
    config
  end

  @impl Config.Provider
  def load(config, path) do
    base_config =
      if path && File.exists?(path) do
        case File.read(path) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, file_config} ->
                Logger.info("Loaded configuration from #{path}")
                Map.new(file_config)

              {:error, reason} ->
                Logger.warning("Failed to parse config: #{inspect(reason)}")
                %{}
            end

          {:error, reason} ->
            Logger.warning("Failed to read config: #{inspect(reason)}")
            %{}
        end
      else
        %{}
      end

    merged =
      base_config
      |> merge_defaults()
      |> load_from_env()

    Config.Reader.merge(config, elixir_claw: Map.to_list(merged))
  end

  defp merge_defaults(config) do
    defaults = %{
      gateway_host: "127.0.0.1",
      gateway_port: 18789,
      node_id: generate_node_id(),
      display_name: "ElixirClaw Node",
      caps: [
        "camera.snap",
        "camera.clip",
        "screen.record",
        "screen.snap",
        "system.run",
        "system.notify",
        "location.get",
        "notifications.send"
      ],
      allowed_commands: [],
      reconnect: true,
      log_level: :info,
      device_id: nil,
      public_key: nil,
      private_key: nil,
      secret_key: nil,
      token: nil,
      client_id: "elixir_claw"
    }

    Map.merge(defaults, config)
  end

  defp load_from_env(config) do
    config
    |> Map.put(:gateway_host, System.get_env("ELIXIR_CLAW_HOST", config.gateway_host))
    |> Map.put(
      :gateway_port,
      System.get_env("ELIXIR_CLAW_PORT", "#{config.gateway_port}") |> String.to_integer()
    )
    |> Map.put(:node_id, System.get_env("ELIXIR_CLAW_NODE_ID", config.node_id))
    |> Map.put(:token, System.get_env("ELIXIR_CLAW_TOKEN", config[:token]))
    |> Map.put(:device_id, System.get_env("ELIXIR_CLAW_DEVICE_ID", config.device_id))
    |> Map.put(:display_name, System.get_env("ELIXIR_CLAW_DISPLAY_NAME", config.display_name))
    |> Map.put(:client_id, System.get_env("ELIXIR_CLAW_CLIENT_ID", config.client_id))
  end

  defp generate_node_id do
    "node_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
