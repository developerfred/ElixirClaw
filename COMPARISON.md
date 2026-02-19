# OpenClaw Node Implementations Comparison

## Overview

This document compares all known OpenClaw node implementations across different programming languages.

---

## Implementations Matrix

| Implementation | Language | Stars | Status | Target |
|----------------|----------|-------|--------|--------|
| **ElixirClaw** | Elixir | - | Active | This project |
| **ZiggyStarClaw** | Zig | 2 | Active (v0.3.4) | Linux, Windows, Android, WASM |
| **Clawgo** | Go | 23 | Active | Raspberry Pi / Linux |
| **ZeroClaw** | Rust | ~200+ | Active | Lightweight, 5MB RAM |
| **IronClaw** | Rust | 1909 | Active | Privacy & Security focus |

---

## Detailed Comparison

### 1. ElixirClaw (This Project)

**Language**: Elixir  
**Philosophy**: High-performance, functional, BEAM ecosystem

**Pros**:
- ✅ Built on Erlang/OTP - legendary reliability
- ✅ Excellent for distributed systems
- ✅ Hot code reloading
- ✅ Built-in concurrency (Actors model)
- ✅ Great for 24/7 operation
- ✅ Telemetry & monitoring built-in
- ✅ Security hardened (input sanitization, TLS support)

**Cons**:
- ❌ Larger binary size (~15MB escript)
- ❌ Requires Erlang runtime
- ❌ Smaller ecosystem than Rust/Go

**Features**:
- WebSocket client (Mint) with TLS support
- Node capabilities: camera, screen, notifications, location
- CLI for node management
- Device identity & authentication
- Security: command allowlisting, path traversal prevention
- Config via file or environment variables

**Payment**: `0xd1a8Dd23e356B9fAE27dF5DeF9ea025A602EC81e` (codingsh.eth)

---

### 2. ZiggyStarClaw

**Language**: Zig (77.3%), C++ (15%)  
**Stars**: 2  
**Latest**: v0.3.4 (Feb 2026)

**Philosophy**: Lightweight alternative to official apps

**Pros**:
- ✅ Native performance (no runtime)
- ✅ Cross-platform: Linux, Windows, Android, WASM
- ✅ Small binary size
- ✅ Windows installer available
- ✅ Service/scheduled task support on Windows

**Cons**:
- ❌ Zig is still evolving (breaking changes)
- ❌ Smaller community
- ❌ More complex build system

**Features**:
- CLI approvals management
- Interactive REPL mode
- Node mode
- WASM support
- GUI for onboarding (WIP)

**Build**:
```bash
zig build --fetch
zig build
```

---

### 3. Clawgo (Go)

**Language**: Go  
**Stars**: 23  
**Philosophy**: Minimal headless node for Raspberry Pi

**Pros**:
- ✅ Excellent cross-compilation (Raspberry Pi ARM)
- ✅ Mature ecosystem
- ✅ Small binaries
- ✅ Great for embedded devices

**Cons**:
- ❌ No TLS mentioned
- ❌ Limited features
- ❌ Basic security

**Features**:
- Voice transcript events (stdin/FIFO)
- Chat stream + TTS
- Multiple TTS engines: system, piper, elevenlabs
- Bonjour service discovery

**Build**:
```bash
go build ./cmd/clawgo
GOOS=linux GOARCH=arm64 go build -o /tmp/clawgo-linux-arm64 ./cmd/clawgo
```

---

### 4. ZeroClaw (Rust)

**Language**: Rust  
**Stars**: ~200+  
**Philosophy**: Zero overhead, zero compromise

**Pros**:
- ✅ Extremely lightweight (5MB RAM)
- ✅ Memory safety (no GC)
- ✅ Fast startup
- ✅ 22+ AI providers
- ✅ Trait-based abstractions

**Cons**:
- ❌ More complex code
- ❌ Longer compile times

**Features**:
- Self-contained binary
- 22+ AI providers (Claude, OpenAI, Ollama, Groq, Mistral)
- Multiple messaging platforms
- Service management
- Daemon mode

---

### 5. IronClaw (Rust)

**Language**: Rust  
**Stars**: 1909  
**Philosophy**: Privacy and security focused

**Pros**:
- ✅ Largest community
- ✅ Privacy-first design
- ✅ Production tested
- ✅ Apache 2.0 license

**Cons**:
- ❌ Heavier than ZeroClaw
- ❌ More dependencies

**Features**:
- Full OpenClaw replacement
- Secure by default
- Multiple platform support

---

## Feature Comparison Matrix

| Feature | ElixirClaw | ZiggyStarClaw | Clawgo | ZeroClaw | IronClaw |
|---------|------------|---------------|--------|----------|----------|
| **TLS/SSL** | ✅ | ? | ❌ | ✅ | ✅ |
| **Camera** | ✅ | ✅ | ❌ | ? | ? |
| **Screen** | ✅ | ✅ | ❌ | ? | ? |
| **Notifications** | ✅ | ✅ | ❌ | ? | ? |
| **Location** | ✅ | ? | ❌ | ? | ? |
| **System Commands** | ✅ | ✅ | ✅ | ? | ? |
| **CLI** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Interactive Mode** | ✅ | ✅ | ❌ | ? | ? |
| **Node Mode** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Hot Reload** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **WASM** | ❌ | ✅ | ❌ | ❌ | ? |
| **Android** | ❌ | ✅ | ❌ | ? | ? |
| **Tests** | ❌ | ❌ | ❌ | ? | ? |

---

## Security Comparison

| Feature | ElixirClaw | ZiggyStarClaw | Clawgo |
|---------|------------|---------------|--------|
| Input Sanitization | ✅ | ? | ❌ |
| Command Allowlist | ✅ | ? | ❌ |
| Path Traversal Prevention | ✅ | ? | ❌ |
| TLS Support | ✅ | ? | ❌ |
| Secure Config Storage | ✅ (600) | ? | ❌ |
| Private Network Only | ✅ (default) | ? | ❌ |

---

## When to Use Each

### Use ElixirClaw if:
- You value reliability and 24/7 operation
- You're already in the BEAM ecosystem
- You need built-in telemetry
- You want functional programming
- You need hot code upgrades

### Use ZiggyStarClaw if:
- You need WASM support
- You need Android support
- You want smallest native binary
- You prefer Zig

### Use Clawgo if:
- You're on Raspberry Pi
- You need minimal footprint
- You want voice/TTS features

### Use ZeroClaw if:
- You need absolute minimum resource usage
- You want 5MB RAM footprint
- You need many AI providers

### Use IronClaw if:
- You prioritize privacy/security
- You want the largest community
- You need production-tested code

---

## Conclusion

Each implementation has its place:

- **ElixirClaw** brings the BEAM's legendary reliability to OpenClaw nodes
- **ZiggyStarClaw** targets cross-platform (including WASM/Android)
- **Clawgo** is perfect for Raspberry Pi minimal setups
- **ZeroClaw** wins on absolute resource minimalism
- **IronClaw** leads in community size and production readiness

ElixirClaw differentiates by being the **only Elixir implementation**, bringing:
- OTP's fault tolerance
- Built-in telemetry
- Hot code reloading
- Security hardening from the start

---

## Contribute

Want to add your implementation? Submit a PR to update this document.

**Payment Addresses** (support if ElixirClaw helps your business):
- **Ethereum/ENS**: 0xd1a8Dd23e356B9fAE27dF5DeF9ea025A602EC81e (codingsh.eth)
- **Polkadot**: 5DJV8DsPT3KH1rzvqTGqJ7WsCNnFt5tBn6R9yfe8SGi7YmYD
- **Solana**: EyFovdqgnLAicTrDzJzjawRciLHTtq5W7ZkUV5Q3azmb
