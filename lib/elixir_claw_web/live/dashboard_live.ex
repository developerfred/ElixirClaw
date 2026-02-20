defmodule ElixirClawWeb.DashboardLive do
  use ElixirClawWeb, :live_view

  alias ElixirClaw.DashboardStub

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ElixirClaw.Events.subscribe()
      :timer.send_interval(1000, :tick)
    end

    socket =
      socket
      |> assign(:page_title, "ElixirClaw Dashboard")
      |> assign(:summary, DashboardStub.summary())
      |> assign(:nodes, get_nodes())
      |> assign(:events, [])
      |> assign(:pending_approvals, get_pending_approvals())
      |> assign(:stats, DashboardStub.node_stats())
      |> assign(:telemetry, DashboardStub.telemetry_stats())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <header class="dashboard-header">
        <h1><%= @page_title %></h1>
        <div class="status-badge">
          Status: <span class="status-text"><%= @summary.connected_nodes %>/<%= @summary.total_nodes %> nodes connected</span>
        </div>
      </header>

      <div class="stats-grid">
        <div class="stat-card">
          <h3>Total Nodes</h3>
          <p class="stat-value"><%= @summary.total_nodes %></p>
        </div>
        <div class="stat-card">
          <h3>Connected</h3>
          <p class="stat-value connected"><%= @summary.connected_nodes %></p>
        </div>
        <div class="stat-card">
          <h3>Pending Approvals</h3>
          <p class="stat-value"><%= @summary.pending_approvals %></p>
        </div>
        <div class="stat-card">
          <h3>Recent Events</h3>
          <p class="stat-value"><%= @summary.recent_events %></p>
        </div>
      </div>

      <div class="dashboard-content">
        <section class="nodes-section">
          <h2>Connected Nodes</h2>
          <div class="node-list">
            <%= for node <- @nodes do %>
              <div class={"node-card #{node.status}"}>
                <div class="node-header">
                  <strong><%= node.display_name %></strong>
                  <span class="node-status"><%= node.status %></span>
                </div>
                <div class="node-details">
                  <p>ID: <%= node.id %></p>
                  <p>Capabilities: <%= length(node.caps || []) %></p>
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <section class="approvals-section">
          <h2>Pending Approvals</h2>
          <%= if Enum.empty?(@pending_approvals) do %>
            <p class="empty-state">No pending approvals</p>
          <% else %>
            <div class="approval-list">
              <%= for approval <- @pending_approvals do %>
                <div class="approval-item">
                  <div class="approval-info">
                    <strong>Request:</strong> <%= approval.request_id %><br />
                    <strong>Command:</strong> <%= approval.command %>
                  </div>
                  <div class="approval-actions">
                    <button phx-click="approve" phx-value-id={approval.request_id} class="btn-approve">
                      Approve
                    </button>
                    <button phx-click="reject" phx-value-id={approval.request_id} class="btn-reject">
                      Reject
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </section>

        <section class="events-section">
          <h2>Recent Events</h2>
          <%= if Enum.empty?(@events) do %>
            <p class="empty-state">No recent events</p>
          <% else %>
            <div class="event-list">
              <%= for event <- Enum.take(@events, 10) do %>
                <div class={"event-item #{event.type}"}>
                  <span class="event-time"><%= format_time(event.timestamp) %></span>
                  <span class="event-type"><%= event.type %></span>
                  <span class="event-capability"><%= event.capability %></span>
                  <span class="event-node"><%= event.node_id %></span>
                </div>
              <% end %>
            </div>
          <% end %>
        </section>

        <section class="telemetry-section">
          <h2>Telemetry</h2>
          <div class="telemetry-grid">
            <div class="telemetry-item">
              <h4>Total Events</h4>
              <p><%= @telemetry.total_events %></p>
            </div>
            <div class="telemetry-item">
              <h4>Avg Response Time</h4>
              <p><%= Float.round(@telemetry.average_response_time_ms, 1) %> ms</p>
            </div>
            <div class="telemetry-item">
              <h4>Error Rate</h4>
              <p><%= @telemetry.error_rate_percent %>%</p>
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("approve", %{"id" => request_id}, socket) do
    {:ok, _} = DashboardStub.approve_request(request_id)
    {:noreply, assign(socket, :pending_approvals, get_pending_approvals())}
  end

  @impl true
  def handle_event("reject", %{"id" => request_id}, socket) do
    {:ok, _} = DashboardStub.reject_request(request_id)
    {:noreply, assign(socket, :pending_approvals, get_pending_approvals())}
  end

  @impl true
  def handle_info({:elixir_claw_event, event}, socket) do
    events = [event | socket.assigns.events] |> Enum.take(100)
    {:noreply, assign(socket, :events, events)}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :summary, DashboardStub.summary())}
  end

  defp get_nodes do
    [
      %{
        id: "node_demo_1",
        display_name: "Demo Node 1",
        status: "connected",
        caps: ["camera.snap", "screen.snap", "system.run"]
      },
      %{
        id: "node_demo_2",
        display_name: "Demo Node 2",
        status: "disconnected",
        caps: ["camera.snap", "screen.snap"]
      }
    ]
  end

  defp get_pending_approvals do
    [
      %{request_id: "req_12345", command: "system.run", args: %{"cmd" => "ls -la"}}
    ]
  end

  defp format_time(timestamp) do
    DateTime.from_unix!(timestamp, :millisecond)
    |> Calendar.strftime("%H:%M:%S")
  end
end
