defmodule ElixirClawWeb.NodesLive do
  use ElixirClawWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :nodes, get_nodes())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="nodes-page">
      <h1>Connected Nodes</h1>
      <div class="node-grid">
        <%= for node <- @nodes do %>
          <div class={"node-card #{node.status}"}>
            <h3><%= node.display_name %></h3>
            <p>ID: <%= node.id %></p>
            <p>Status: <%= node.status %></p>
            <p>Capabilities: <%= Enum.join(node.caps, ", ") %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_nodes do
    [
      %{
        id: "node_1",
        display_name: "Node 1",
        status: "connected",
        caps: ["camera.snap", "screen.snap"]
      },
      %{id: "node_2", display_name: "Node 2", status: "disconnected", caps: ["camera.snap"]}
    ]
  end
end

defmodule ElixirClawWeb.ApprovalsLive do
  use ElixirClawWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :approvals, get_approvals())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="approvals-page">
      <h1>Pending Approvals</h1>
      <%= if Enum.empty?(@approvals) do %>
        <p>No pending approvals</p>
      <% else %>
        <div class="approval-list">
          <%= for approval <- @approvals do %>
            <div class="approval-item">
              <p>Request ID: <%= approval.request_id %></p>
              <p>Command: <%= approval.command %></p>
              <button phx-click="approve" phx-value-id={approval.request_id}>Approve</button>
              <button phx-click="reject" phx-value-id={approval.request_id}>Reject</button>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_approvals, do: []
end

defmodule ElixirClawWeb.TelemetryLive do
  use ElixirClawWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :telemetry, ElixirClaw.DashboardStub.telemetry_stats())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="telemetry-page">
      <h1>Telemetry</h1>
      <div class="telemetry-stats">
        <div class="stat">
          <h3>Total Events</h3>
          <p><%= @telemetry.total_events %></p>
        </div>
        <div class="stat">
          <h3>Events Last Hour</h3>
          <p><%= @telemetry.events_last_hour %></p>
        </div>
        <div class="stat">
          <h3>Avg Response Time</h3>
          <p><%= Float.round(@telemetry.average_response_time_ms, 1) %> ms</p>
        </div>
        <div class="stat">
          <h3>Error Rate</h3>
          <p><%= @telemetry.error_rate_percent %>%</p>
        </div>
      </div>
    </div>
    """
  end
end

defmodule ElixirClawWeb.ConfigLive do
  use ElixirClawWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    config = Application.get_all_env(:elixir_claw) |> Map.new()
    {:ok, assign(socket, :config, config)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="config-page">
      <h1>Configuration</h1>
      <pre><%= inspect(@config, pretty: true) %></pre>
    </div>
    """
  end
end
