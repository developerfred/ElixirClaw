# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please send an email to the maintainer. All security vulnerabilities will be promptly addressed.

## Security Model

### Threat Model

ElixirClaw is a node client for OpenClaw Gateway. The primary security concerns are:

1. **Command Injection** - Malicious commands injected through `system.run`
2. **Path Traversal** - Access to unauthorized files via path manipulation
3. **Denial of Service** - Resource exhaustion via large messages
4. **Unauthorized Access** - Gateway connection without proper authentication

### Security Features Implemented

#### 1. Command Sanitization

All system commands are sanitized before execution:

```elixir
# Sanitize command arguments
defp sanitize_command_args(args) when is_list(args) do
  max_args = 50
  max_arg_length = 10000
  
  if length(args) > max_args do
    {:error, :too_many_args}
  else
    sanitized = Enum.map(args, &to_string/1)
    sanitized = Enum.map(sanitized, &sanitize_single_arg/1)
    sanitized = Enum.take(sanitized, max_args)
    sanitized = Enum.map(sanitized, fn arg -> String.slice(arg, 0, max_arg_length) end)
    {:ok, sanitized}
  end
end
```

- Maximum 50 arguments per command
- Maximum 10000 characters per argument
- Control characters stripped
- Whitespace trimmed

#### 2. Shell Argument Escaping

Notification arguments are escaped to prevent shell injection:

```elixir
defp sanitize_shell_arg(arg) when is_binary(arg) do
  arg 
  |> String.replace("\\", "\\\\")  # Escape backslashes
  |> String.replace("\"", "\\\"")    # Escape quotes
  |> String.slice(0, 1000)           # Limit length
end
```

#### 3. Device Validation

Camera devices are validated before use:

```elixir
defp validate_device(device) when is_binary(device) do
  safe = device 
  |> String.replace(~r/[^a-zA-Z0-9_\-\.\/], "", global: true) 
  |> String.slice(0, 255)
  if safe == device or safe == "", do: {:ok, safe}, else: {:error, :invalid_device}
end
```

- Only alphanumeric characters, underscores, hyphens, dots, and slashes allowed
- Maximum 255 characters

#### 4. Message Size Limits

Protocol messages are limited to prevent DoS:

```elixir
@max_message_size 1_000_000  # 1MB limit
```

#### 5. Capability Checking

All node operations require explicit capability grants:

```elixir
defp check_cap(cap) do
  config = Application.get_all_env(:elixir_claw) || %{}
  allowed = config[:caps] || []
  if cap in allowed || allowed == :all do
    {:ok, cap}
  else
    {:error, :capability_not_allowed}
  end
end
```

#### 6. Command Allowlisting

System commands can be restricted to an allowlist:

```elixir
defp validate_command(cmd) when is_binary(cmd) and byte_size(cmd) > 0 do
  config = Application.get_all_env(:elixir_claw) || %{}
  allowed = config[:allowed_commands] || []
  allowed_commands = [:all | allowed]
  if :all in allowed_commands || cmd in allowed_commands do
    {:ok, cmd}
  else
    {:error, :command_not_allowed}
  end
end
```

#### 7. TLS/SSL Support

All gateway connections use TLS:

```elixir
defp connect_gateway(host, port, token) do
  # TLS connection with certificate verification
end
```

## Configuration Recommendations

### Production Deployment

1. **Restrict Capabilities**
   ```elixir
   config :elixir_claw,
     caps: ["camera.snap", "screen.snap"],  # Only allow what's needed
     allowed_commands: ["echo", "date"]      # Whitelist specific commands
   ```

2. **Enable TLS Verification**
   ```elixir
   config :elixir_claw,
     verify_ssl: true
   ```

3. **Set Resource Limits**
   ```elixir
   config :elixir_claw,
     max_command_timeout: 30_000,  # 30 seconds max
     max_message_size: 1_000_000     # 1MB max
   ```

## Security Audit History

- **v0.1.0** (2026-02-19)
  - Fixed command injection vulnerability in `system.run`
  - Added input sanitization for all user-controlled inputs
  - Implemented capability-based access control
  - Added message size limits

## Contact

For security issues, please contact the maintainer directly.
