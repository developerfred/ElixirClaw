# Contributing to ElixirClaw

Thanks for helping out! This guide covers the basics.

## Setup

Requirements: Elixir 1.19+ and Erlang/OTP 28.

```bash
git clone https://github.com/developerfred/ElixirClaw.git
cd ElixirClaw
mix deps.get
mix test
```

## Before you open a PR

CI runs the same checks, so run them locally first:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

## Tests

- Tests tagged `:hardware` need real tooling on the host (camera, `scrot`/`screencapture`, `notify-send`, `gpspipe`). They are skipped by default; run everything with:

  ```bash
  ELIXIR_CLAW_HARDWARE_TESTS=1 mix test
  ```

- New behavior needs a test. Tests that can run on any machine should not be tagged `:hardware`.
- `ElixirClaw.Application` already starts the registry and supervisors; tests should use those instead of starting their own.

## Pull requests

- Keep PRs focused; one change per PR.
- Describe what changed and why, and link the issue if there is one.
- Update `CHANGELOG.md` under `[Unreleased]` for user-visible changes.
- Anything touching `system.run`, input sanitization or auth should be explained in the PR; see [SECURITY.md](./SECURITY.md).

## Reporting bugs and vulnerabilities

Open an issue with steps to reproduce, your OS and your Elixir/OTP versions. For security problems, follow [SECURITY.md](./SECURITY.md) instead of opening a public issue.

## Code of conduct

By participating you agree to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).
