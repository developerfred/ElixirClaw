defmodule ElixirClawWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", ElixirClawWeb do
    pipe_through(:browser)

    live("/", DashboardLive)
    live("/nodes", NodesLive)
    live("/approvals", ApprovalsLive)
    live("/telemetry", TelemetryLive)
    live("/config", ConfigLive)
  end

  scope "/api", ElixirClawWeb do
    pipe_through(:api)

    get("/status", StatusController, :index)
    get("/nodes", NodesController, :index)
    get("/metrics", MetricsController, :index)
  end
end
