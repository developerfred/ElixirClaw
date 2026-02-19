import Config

config :elixir_claw,
  gateway_host: "127.0.0.1",
  gateway_port: 18789,
  log_level: :info,
  caps: [
    "camera.snap",
    "camera.clip",
    "screen.record",
    "screen.snap",
    "system.run",
    "system.notify",
    "location.get",
    "notifications.send"
  ],
  allowed_commands: []

config :logger,
  level: :info

config :mint,
  log: false
