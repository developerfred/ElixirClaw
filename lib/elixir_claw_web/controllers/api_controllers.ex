defmodule ElixirClawWeb.StatusController do
  use ElixirClawWeb, :controller

  def index(conn, _params) do
    json(conn, ElixirClaw.DashboardStub.summary())
  end
end

defmodule ElixirClawWeb.NodesController do
  use ElixirClawWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      nodes: [
        %{id: "node_1", status: "connected"},
        %{id: "node_2", status: "disconnected"}
      ]
    })
  end
end

defmodule ElixirClawWeb.MetricsController do
  use ElixirClawWeb, :controller

  def index(conn, _params) do
    json(conn, ElixirClaw.DashboardStub.telemetry_stats())
  end
end
