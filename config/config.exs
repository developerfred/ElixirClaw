import Config

# Compile-time settings for the optional dashboard. Runtime settings (port,
# secret key, ...) are applied by ElixirClaw.Application when the dashboard
# is enabled; see ElixirClaw.Dashboard.
config :elixir_claw, ElixirClawWeb.Endpoint,
  pubsub_server: ElixirClaw.PubSub,
  render_errors: [
    formats: [html: ElixirClawWeb.ErrorHTML, json: ElixirClawWeb.ErrorJSON],
    layout: false
  ]
