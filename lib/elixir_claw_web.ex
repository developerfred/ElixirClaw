defmodule ElixirClawWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: ElixirClawWeb
      import Plug.Conn
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {ElixirClawWeb.Layouts, :live}
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.LiveView.Helpers
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      import Phoenix.HTML
      import Phoenix.HTML.Form
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule ElixirClawWeb.Layouts do
  use Phoenix.Component

  def live(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title><%= assigns[:page_title] || "ElixirClaw Dashboard" %></title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; color: #333; }
          .dashboard { max-width: 1400px; margin: 0 auto; padding: 20px; }
          h1 { margin-bottom: 20px; color: #2563eb; }
          h2 { margin-bottom: 15px; color: #374151; }
          h3 { font-size: 14px; color: #6b7280; margin-bottom: 8px; }
          .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
          .stat-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
          .stat-value { font-size: 36px; font-weight: bold; color: #2563eb; }
          .stat-value.connected { color: #059669; }
          .dashboard-content { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
          section { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
          .node-list { display: grid; gap: 10px; }
          .node-card { padding: 15px; border: 1px solid #e5e7eb; border-radius: 6px; }
          .node-card.connected { background: #ecfdf5; border-color: #10b981; }
          .node-card.disconnected { background: #fef2f2; border-color: #ef4444; }
          .node-header { display: flex; justify-content: space-between; margin-bottom: 10px; }
          .node-status { font-size: 12px; padding: 2px 8px; border-radius: 4px; background: #e5e7eb; }
          .approval-item { padding: 15px; border: 1px solid #e5e7eb; border-radius: 6px; margin-bottom: 10px; }
          .approval-actions { margin-top: 10px; }
          button { padding: 8px 16px; border-radius: 6px; border: none; cursor: pointer; margin-right: 8px; }
          .btn-approve { background: #10b981; color: white; }
          .btn-reject { background: #ef4444; color: white; }
          .event-item { padding: 8px; border-bottom: 1px solid #e5e7eb; font-size: 14px; }
          .telemetry-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
          .telemetry-item { text-align: center; padding: 10px; background: #f9fafb; border-radius: 6px; }
          .empty-state { color: #9ca3af; font-style: italic; }
        </style>
      </head>
      <body>
        <div class="dashboard">
          <%= render_slot(@inner_block) %>
        </div>
      </body>
    </html>
    """
  end
end
