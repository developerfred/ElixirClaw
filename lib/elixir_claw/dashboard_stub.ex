defmodule ElixirClaw.DashboardStub do
  @moduledoc """
  Dashboard stub module for ElixirClaw.

  This provides a placeholder implementation for a web dashboard.
  The actual Phoenix LiveView dashboard would be implemented separately
  when Phoenix is added as a dependency.

  ## Usage Example
      # In a future Phoenix router:
      # live "/dashboard", ElixirClawWeb.Dashboard
      
      # Current stub usage:
      IO.puts("Dashboard stub: Shows planned features")
  """

  defstruct [
    :nodes,
    :telemetry_events,
    :pending_approvals,
    :config,
    :status
  ]

  @doc """
  Create a new dashboard stub with placeholder data.
  """
  def new do
    %__MODULE__{
      nodes: [
        %{id: "node_demo_1", status: "connected", display_name: "Demo Node 1"},
        %{id: "node_demo_2", status: "disconnected", display_name: "Demo Node 2"}
      ],
      telemetry_events: [
        %{
          timestamp: "2025-01-15T10:30:00Z",
          event: "node.invoke",
          node_id: "node_demo_1",
          command: "camera.snap"
        },
        %{
          timestamp: "2025-01-15T10:31:00Z",
          event: "gateway.connected",
          node_id: "node_demo_1",
          gateway_host: "127.0.0.1"
        }
      ],
      pending_approvals: [
        %{
          request_id: "req_12345",
          command: "system.run",
          args: %{"cmd" => "ls -la"},
          requested_at: "2025-01-15T10:29:00Z"
        }
      ],
      config: %{
        gateway_host: "127.0.0.1",
        gateway_port: 18789,
        log_level: :info
      },
      status: "stub_ready"
    }
  end

  @doc """
  Get dashboard status summary.
  """
  def summary do
    %{
      total_nodes: 2,
      connected_nodes: 1,
      pending_approvals: 1,
      recent_events: 2,
      telemetry_enabled: true,
      auth_enabled: true,
      version: "0.1.0"
    }
  end

  @doc """
  Simulate approving a request (stub implementation).
  """
  def approve_request(request_id) do
    IO.puts("Dashboard stub: Approving request #{request_id}")
    {:ok, %{request_id: request_id, approved: true, timestamp: DateTime.utc_now()}}
  end

  @doc """
  Simulate rejecting a request (stub implementation).
  """
  def reject_request(request_id) do
    IO.puts("Dashboard stub: Rejecting request #{request_id}")
    {:ok, %{request_id: request_id, rejected: true, timestamp: DateTime.utc_now()}}
  end

  @doc """
  Get node statistics.
  """
  def node_stats do
    %{
      total: 2,
      connected: 1,
      disconnected: 1,
      by_status: %{
        connected: 1,
        disconnected: 1,
        authenticating: 0,
        error: 0
      },
      capabilities: %{
        "camera.snap" => 2,
        "screen.snap" => 2,
        "system.run" => 2,
        "location.get" => 1
      }
    }
  end

  @doc """
  Get telemetry statistics.
  """
  def telemetry_stats do
    %{
      total_events: 156,
      events_last_hour: 12,
      events_by_type: %{
        "node.invoke" => 45,
        "gateway.connected" => 23,
        "gateway.disconnected" => 15,
        "auth.challenge" => 67,
        "telemetry.debug" => 6
      },
      average_response_time_ms: 125.5,
      error_rate_percent: 2.3
    }
  end

  @doc """
  Render a simple ASCII dashboard for terminal display.
  """
  def render_ascii do
    """
    ========================================
    ElixirClaw Dashboard (Stub)
    ========================================

    Status Summary:
    - Total Nodes: 2
    - Connected: 1
    - Pending Approvals: 1
    - Recent Events: 2
    - Version: 0.1.0

    Connected Nodes:
    1. node_demo_1 (connected) - Demo Node 1
    2. node_demo_2 (disconnected) - Demo Node 2

    Pending Approvals:
    - req_12345: system.run (ls -la)

    Recent Telemetry:
    - 2025-01-15T10:30:00Z: node.invoke (camera.snap) on node_demo_1
    - 2025-01-15T10:31:00Z: gateway.connected on node_demo_1

    Planned Features:
    • Real-time WebSocket updates
    • Telemetry visualization charts
    • Node configuration management
    • Command approval interface
    • Log viewer with filtering
    • Performance metrics

    ========================================
    Note: This is a stub. Real dashboard requires Phoenix LiveView.
    ========================================
    """
  end

  @doc """
  Generate HTML stub for the dashboard.
  """
  def render_html do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>ElixirClaw Dashboard (Stub)</title>
      <style>
        body { font-family: sans-serif; margin: 20px; }
        .dashboard { max-width: 1200px; margin: 0 auto; }
        .section { margin-bottom: 30px; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .node-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 15px; }
        .node-card { padding: 15px; border: 1px solid #ccc; border-radius: 3px; }
        .connected { background-color: #e8f5e8; }
        .disconnected { background-color: #ffe6e6; }
        .stats { display: flex; gap: 20px; }
        .stat-card { flex: 1; padding: 15px; text-align: center; background-color: #f5f5f5; }
      </style>
    </head>
    <body>
      <div class="dashboard">
        <h1>ElixirClaw Dashboard (Stub)</h1>
        <p>This is a placeholder for the future Phoenix LiveView dashboard.</p>
        
        <div class="section">
          <h2>Status Summary</h2>
          <div class="stats">
            <div class="stat-card">
              <h3>2</h3>
              <p>Total Nodes</p>
            </div>
            <div class="stat-card">
              <h3>1</h3>
              <p>Connected</p>
            </div>
            <div class="stat-card">
              <h3>1</h3>
              <p>Pending Approvals</p>
            </div>
            <div class="stat-card">
              <h3>2</h3>
              <p>Recent Events</p>
            </div>
          </div>
        </div>
        
        <div class="section">
          <h2>Connected Nodes</h2>
          <div class="node-list">
            <div class="node-card connected">
              <strong>node_demo_1</strong><br/>
              Status: connected<br/>
              Display: Demo Node 1
            </div>
            <div class="node-card disconnected">
              <strong>node_demo_2</strong><br/>
              Status: disconnected<br/>
              Display: Demo Node 2
            </div>
          </div>
        </div>
        
        <div class="section">
          <h2>Planned Features</h2>
          <ul>
            <li>Real-time WebSocket updates with Phoenix LiveView</li>
            <li>Telemetry visualization with charts</li>
            <li>Node configuration management interface</li>
            <li>Command approval workflow</li>
            <li>Structured log viewer with filtering</li>
            <li>Performance metrics dashboard</li>
            <li>Ed25519 authentication status</li>
            <li>Gateway connection monitoring</li>
          </ul>
        </div>
        
        <div class="section">
          <h2>Implementation Notes</h2>
          <p>To implement the real dashboard:</p>
          <ol>
            <li>Add Phoenix and LiveView dependencies to mix.exs</li>
            <li>Create Phoenix application structure</li>
            <li>Implement WebSocket handlers for real-time updates</li>
            <li>Create LiveView components for each dashboard section</li>
            <li>Integrate with existing ElixirClaw telemetry and registry</li>
            <li>Add authentication and authorization</li>
            <li>Implement data persistence for historical metrics</li>
          </ol>
        </div>
      </div>
    </body>
    </html>
    """
  end
end
