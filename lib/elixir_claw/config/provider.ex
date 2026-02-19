defmodule ElixirClaw.Config.Provider do
  @moduledoc """
  Configuration provider for ElixirClaw.
  Loads configuration from file with secure defaults.
  """
  require Logger

  @impl true
  def init(config) do
    config_path = config[:config_path] || default_config_path()

    merged =
      config
      |> merge_defaults()
      |> load_from_file(config_path)
      |> load_from_env()

    Application.put_all_env(elixir_claw: merged)

    {:ok, config}
  end

  defp default_config_path do
    case :os.type() do
      {:win32, :nt} ->
        Path.join(System.get_env("APPDATA") || "", "elixir_claw/config.json")

      {:unix, :darwin} ->
        Path.join(System.get_env("HOME") || "", ".config/elixir_claw/config.json")

      {:unix, :linux} ->
        Path.join(System.get_env("XDG_CONFIG_HOME") || Path.join(System.get_env("HOME") || "", ".config"), "elixir_claw/config.json")
    end
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
      log_level: :info
    }

    Map.merge(defaults, config)
  end

  defp load_from_file(config, path) do
    if File.exists?(path) do
      case File.read(path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, file_config} ->
              Logger.info("Loaded configuration from #{path}")
              Map.merge(config, file_config)

            {:error, reason} ->
              Logger.warning("Failed to parse config: #{inspect(reason)}")
              config
          end

        {:error, reason} ->
          Logger.warning("Failed to read config: #{inspect(reason)}")
          config
      end
    else
      config
    end
  end

  defp load_from_env(config) do
    config
    |> Map.put(:gateway_host, System.get_env("ELIXIR_CLAW_HOST", config.gateway_host))
    |> Map.put(:gateway_port, System.get_env("ELIXIR_CLAW_PORT", "#{config.gateway_port}") |> String.to_integer())
    |> Map.put(:node_id, System.get_env("ELIXIR_CLAW_NODE_ID", config.node_id))
    |> Map.put(:token, System.get_env("ELIXIR_CLAW_TOKEN", config[:token]))
  end

  defp generate_node_id do
    "node_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
