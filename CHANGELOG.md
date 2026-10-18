# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- GitHub Actions CI: format check, `--warnings-as-errors` compile, tests, escript build and Docker build.
- `CONTRIBUTING.md`, `CHANGELOG.md` and `CODE_OF_CONDUCT.md`.
- `:hardware` test tag for tests that need camera, screen, notification or GPS tooling. Skipped by default; enable with `ELIXIR_CLAW_HARDWARE_TESTS=1`.

### Security
- Upgraded dependencies to clear 30+ advisories from `mix hex.audit` (cowboy, cowlib, plug, plug_cowboy, phoenix, phoenix_live_view 0.20 -> 1.2, mint, hpax). `cowlib` EEF-CVE-2026-43966 (MEDIUM) remains: 2.21.0 is the latest release and has no fix yet.

### Fixed
- Compiler warnings in `ElixirClaw.Node` (ungrouped `execute` clauses), `ElixirClaw.LLM` (deprecated charlist, unused variables) and `ElixirClawWeb.Endpoint` (unused function).
- `GatewaySupervisorTest` tried to start a supervisor the application already runs, and passed a keyword list where `Gateway.start_link/1` expects a map.

### Changed
- Controllers use `formats: [:json]` instead of the deprecated `:namespace` option.
- Dockerfile: the runtime image now includes Erlang (the escript needs it) and uses the correct Alpine package names (`libnotify`, `v4l-utils`). Added `.dockerignore`.
- Removed the `deps.get` alias from `mix.exs`; it started the app right after fetching dependencies, which broke `mix deps.get --only prod` in Docker.
- Code formatted with `mix format`.

## [0.1.0]

### Added
- Initial OpenClaw node client: gateway WebSocket connection, Ed25519 device auth, structured telemetry, capability event streaming, LiveView dashboard and LLM integrations (Claude, GPT-4, NVIDIA, OpenRouter, OpenCode).
