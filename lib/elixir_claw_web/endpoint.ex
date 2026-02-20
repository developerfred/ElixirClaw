defmodule ElixirClawWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :elixir_claw

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: {__MODULE__, :session, []}]]
  )

  plug(Plug.Static, at: "/", from: :elixir_claw, gzip: false, only: ~w(css fonts images js))

  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(ElixirClawWeb.Router)

  def session(_conn) do
    %{}
  end

  defp code_reloading? do
    Application.get_env(:elixir_claw, __MODULE__)[:code_reloader] || false
  end
end
