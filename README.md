# ElixirClaw 🦞⚡

<p align="center">
  <img src="https://img.shields.io/github/stars/developerfred/ElixirClaw" alt="stars">
  <img src="https://img.shields.io/github/license/developerfred/ElixirClaw" alt="license">
  <img src="https://img.shields.io/elixir/v/elixir_claw" alt="elixir">
</p>

**High-performance OpenClaw Node implemented in pure Elixir.** Connect your device to OpenClaw Gateway and expose AI capabilities.

> Built on the BEAM - the same technology that powers WhatsApp, Ericsson, and Nintendo Online

## Why ElixirClaw?

| Feature | Benefit |
|---------|---------|
| **OTP Reliability** | 99.9999999% uptime - it just runs forever |
| **Hot Reload** | Update your AI node without restarting |
| **Built-in Telemetry** | See your agent thinking in real-time |
| **Security First** | Input sanitization, TLS, command allowlisting |
| **BEAM Distribution** | Scale to 1000 nodes with built-in clustering |

## Quick Start

```bash
# Clone and build
git clone https://github.com/developerfred/ElixirClaw.git
cd elixir-claw
mix deps.get
mix escript.build

# Register your node
./elixir_claw node-register --display-name "My Elixir Node"

# Start as node
./elixir_claw node-start
```

### Watch the Demo

[![asciicast](https://asciinema.org/a/example.svg)](https://asciinema.org/a/example)

Or run locally:
```bash
# Record your own demo
asciinema rec demo.cast
# Play it back
asciinema play demo.cast
```

### With Docker

```bash
docker-compose up -d
```

## Features

- WebSocket client with TLS support
- Camera capture (macOS, Linux)
- Screen capture & recording
- System notifications
- Location services
- Command execution with allowlist
- Device identity & authentication

## Commands

```bash
./elixir_claw status              # Show node status
./elixir_claw node-register       # Register with gateway
./elixir_claw node-start         # Start node mode
./elixir_claw node-stop          # Stop node
./elixir_claw approvals          # List pending approvals
./elixir_claw -i                # Interactive mode
```

## Configuration

```json
{
  "gateway_host": "127.0.0.1",
  "gateway_port": 18789,
  "display_name": "My Node",
  "caps": ["camera.snap", "screen.snap", "system.notify"]
}
```

Environment variables:
- `ELIXIR_CLAW_HOST` - Gateway host
- `ELIXIR_CLAW_PORT` - Gateway port
- `ELIXIR_CLAW_NODE_ID` - Node ID
- `ELIXIR_CLAW_TOKEN` - Auth token

## Comparison

See [COMPARISON.md](./COMPARISON.md) for detailed comparison with ZiggyStarClaw, Clawgo, ZeroClaw, and IronClaw.

## Roadmap

- [x] Real Ed25519 authentication
- [x] Unified configuration (Config.Provider)
- [x] Structured logging with telemetry
- [x] Progress event streaming
- [x] Phoenix LiveView Dashboard
- [x] LLM integration (Claude/GPT-4)
- [ ] Livebook integration
- [ ] Nx/Bumblebee for local AI
- [ ] More platform support

## Phase 3 Features

### Real-time Event Streaming

Track capability execution progress in real-time:

```elixir
# Subscribe to events
ElixirClaw.Events.subscribe("my_node")

# Execute with progress tracking
ElixirClaw.Node.execute("screen.record", %{duration: 10}, %{
  node_id: "my_node",
  request_id: "req_123"
})
```

### Phoenix LiveView Dashboard

Monitor your nodes in real-time with a web dashboard:

```bash
# Start with dashboard enabled
ELIXIR_CLAW_START_DASHBOARD=true ./elixir_claw node-start

# Open http://localhost:4000
```

Features:
- Real-time node status
- Telemetry visualization
- Command approval interface
- Event streaming

### LLM Integration

Control ElixirClaw with natural language:

```elixir
# Ask Claude to take a screenshot
{:ok, response} = ElixirClaw.LLM.chat_with_claude("Take a screenshot")

# Or use local pattern matching
{:ok, response} = ElixirClaw.LLM.process_command("screenshot my screen")
```

### Stress Testing

Verify 72-hour uptime:

```bash
./stress_test.sh
```

Outputs:
- Memory usage statistics
- Error rates
- Connection stability
- Performance metrics

## Contributing

1. Fork the repo
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a PR

## Support

If this project helps you, consider supporting:

- **Ethereum**: `0xd1a8Dd23e356B9fAE27dF5DeF9ea025A602EC81e`
- **Polkadot**: `5DJV8DsPT3KH1rzvqTGqJ7WsCNnFt5tBn6R9yfe8SGi7YmYD`
- **Solana**: `EyFovdqgnLAicTrDzJzjawRciLHTtq5W7ZkUV5Q3azmb`

## License

MIT License - see [LICENSE](./LICENSE)

