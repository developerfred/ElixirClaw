defmodule ElixirClaw.Dashboard do
  @moduledoc """
  Runtime configuration for the optional Phoenix LiveView dashboard.

  The dashboard is off by default. Enable it with:

      ELIXIR_CLAW_START_DASHBOARD=true

  Other settings:

    * `ELIXIR_CLAW_DASHBOARD_HOST` - bind address, default `127.0.0.1`. The
      dashboard has no authentication, so only change this behind a trusted
      proxy.
    * `ELIXIR_CLAW_DASHBOARD_PORT` - default `4000`.
    * `ELIXIR_CLAW_SECRET_KEY_BASE` - at least 64 bytes. A random key is
      generated on every start when unset, which invalidates old sessions.
  """

  @default_host "127.0.0.1"
  @default_port 4000

  @doc "True when the dashboard should start (app env or ELIXIR_CLAW_START_DASHBOARD)."
  def enabled? do
    Application.get_env(:elixir_claw, :start_dashboard, false) or
      System.get_env("ELIXIR_CLAW_START_DASHBOARD") in ["true", "1"]
  end

  @doc "Merges runtime settings into the endpoint config and returns the child specs."
  def children do
    Application.put_env(
      :elixir_claw,
      ElixirClawWeb.Endpoint,
      Keyword.merge(
        Application.get_env(:elixir_claw, ElixirClawWeb.Endpoint, []),
        runtime_config()
      )
    )

    [{Phoenix.PubSub, name: ElixirClaw.PubSub}, ElixirClawWeb.Endpoint]
  end

  @doc false
  def runtime_config do
    [
      http: [
        ip: parse_ip(System.get_env("ELIXIR_CLAW_DASHBOARD_HOST", @default_host)),
        port: port()
      ],
      server: true,
      secret_key_base: secret_key_base(),
      live_view: [signing_salt: random(16)]
    ]
  end

  defp port do
    case Integer.parse(System.get_env("ELIXIR_CLAW_DASHBOARD_PORT", "#{@default_port}")) do
      {port, ""} when port in 1..65_535 -> port
      _ -> @default_port
    end
  end

  defp secret_key_base do
    case System.get_env("ELIXIR_CLAW_SECRET_KEY_BASE") do
      key when is_binary(key) and byte_size(key) >= 64 -> key
      _ -> random(64)
    end
  end

  defp parse_ip(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, ip} -> ip
      {:error, _} -> {127, 0, 0, 1}
    end
  end

  defp random(bytes), do: bytes |> :crypto.strong_rand_bytes() |> Base.encode64()
end
