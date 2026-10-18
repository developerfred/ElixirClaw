defmodule ElixirClawWeb.DashboardTest do
  use ExUnit.Case

  import Phoenix.ConnTest
  import Plug.Conn, only: [put_req_header: 3]
  import Phoenix.LiveViewTest

  @endpoint ElixirClawWeb.Endpoint

  setup_all do
    previous = Application.get_env(:elixir_claw, ElixirClawWeb.Endpoint, [])

    config =
      Keyword.merge(previous, Keyword.put(ElixirClaw.Dashboard.runtime_config(), :server, false))

    Application.put_env(:elixir_claw, ElixirClawWeb.Endpoint, config)
    on_exit(fn -> Application.put_env(:elixir_claw, ElixirClawWeb.Endpoint, previous) end)

    start_supervised!({Phoenix.PubSub, name: ElixirClaw.PubSub})
    start_supervised!(ElixirClawWeb.Endpoint)
    :ok
  end

  setup do
    {:ok, conn: build_conn()}
  end

  describe "LiveView pages" do
    for path <- ["/", "/nodes", "/approvals", "/telemetry", "/config"] do
      test "GET #{path} renders and connects", %{conn: conn} do
        assert {:ok, _view, html} = live(conn, unquote(path))
        assert html =~ "<html"
        assert html =~ "csrf-token"
      end
    end

    test "dashboard shows the summary", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      assert html =~ "ElixirClaw Dashboard"
      assert render(view) =~ "nodes connected"
    end

    test "dashboard handles approve and reject events", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert render_hook(view, "approve", %{"id" => "req_12345"})
      assert render_hook(view, "reject", %{"id" => "req_12345"})
    end

    test "dashboard shows capability events", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      send(
        view.pid,
        {:elixir_claw_event,
         %{
           type: :capability_started,
           capability: "screen.snap",
           node_id: "dash-node",
           request_id: "req-1",
           timestamp: :os.system_time(:millisecond),
           data: %{},
           metadata: %{}
         }}
      )

      html = render(view)
      assert html =~ "screen.snap"
      assert html =~ "dash-node"
    end

    test "serves the LiveView client scripts", %{conn: conn} do
      assert get(conn, "/assets/phoenix.min.js").status == 200
      assert get(conn, "/assets/phoenix_live_view.min.js").status == 200
    end
  end

  describe "JSON API" do
    test "GET /api/status", %{conn: conn} do
      conn = get(conn, "/api/status")
      assert is_map(json_response(conn, 200))
    end

    test "GET /api/nodes", %{conn: conn} do
      conn = get(conn, "/api/nodes")
      assert json_response(conn, 200)
    end

    test "GET /api/metrics", %{conn: conn} do
      conn = get(conn, "/api/metrics")
      assert is_map(json_response(conn, 200))
    end
  end

  describe "error rendering" do
    test "unknown HTML route renders a 404 page", %{conn: conn} do
      conn = get(conn, "/does-not-exist")
      assert response(conn, 404) =~ "Not Found"
    end

    test "unknown API route renders a JSON 404", %{conn: conn} do
      conn = conn |> put_req_header("accept", "application/json") |> get("/api/nope")
      assert json_response(conn, 404) == %{"error" => "Not Found"}
    end
  end
end

defmodule ElixirClaw.DashboardConfigTest do
  use ExUnit.Case

  alias ElixirClaw.Dashboard

  setup do
    names =
      ~w(ELIXIR_CLAW_START_DASHBOARD ELIXIR_CLAW_DASHBOARD_HOST ELIXIR_CLAW_DASHBOARD_PORT ELIXIR_CLAW_SECRET_KEY_BASE)

    old = Map.new(names, &{&1, System.get_env(&1)})

    on_exit(fn ->
      for {name, value} <- old do
        if value, do: System.put_env(name, value), else: System.delete_env(name)
      end
    end)

    Enum.each(names, &System.delete_env/1)
    :ok
  end

  test "is disabled by default" do
    refute Dashboard.enabled?()
  end

  test "is enabled by ELIXIR_CLAW_START_DASHBOARD" do
    System.put_env("ELIXIR_CLAW_START_DASHBOARD", "true")
    assert Dashboard.enabled?()
    System.put_env("ELIXIR_CLAW_START_DASHBOARD", "false")
    refute Dashboard.enabled?()
  end

  test "binds to localhost on port 4000 by default" do
    assert Dashboard.runtime_config()[:http] == [ip: {127, 0, 0, 1}, port: 4000]
  end

  test "reads host and port from the environment" do
    System.put_env("ELIXIR_CLAW_DASHBOARD_HOST", "0.0.0.0")
    System.put_env("ELIXIR_CLAW_DASHBOARD_PORT", "8080")
    assert Dashboard.runtime_config()[:http] == [ip: {0, 0, 0, 0}, port: 8080]
  end

  test "falls back to safe defaults for invalid host or port" do
    System.put_env("ELIXIR_CLAW_DASHBOARD_HOST", "not-an-ip")
    System.put_env("ELIXIR_CLAW_DASHBOARD_PORT", "99999")
    assert Dashboard.runtime_config()[:http] == [ip: {127, 0, 0, 1}, port: 4000]
  end

  test "generates a long random secret key base unless a valid one is given" do
    assert byte_size(Dashboard.runtime_config()[:secret_key_base]) >= 64

    refute Dashboard.runtime_config()[:secret_key_base] ==
             Dashboard.runtime_config()[:secret_key_base]

    System.put_env("ELIXIR_CLAW_SECRET_KEY_BASE", "short")
    assert byte_size(Dashboard.runtime_config()[:secret_key_base]) >= 64

    key = String.duplicate("k", 64)
    System.put_env("ELIXIR_CLAW_SECRET_KEY_BASE", key)
    assert Dashboard.runtime_config()[:secret_key_base] == key
  end
end
