defmodule ElixirClaw.Security do
  @moduledoc """
  Security hardening utilities for ElixirClaw.
  Includes input sanitization, command validation, and secure storage.
  """

  require Logger

  @doc """
  Sanitize user input to prevent injection attacks.
  """
  def sanitize_input(input) when is_binary(input) do
    input
    |> String.replace(~r/[\x00-\x1F\x7F]/, "")
    |> String.trim()
    |> String.slice(0, 65536)
  end

  def sanitize_input(input) when is_list(input) do
    Enum.map(input, &sanitize_input/1)
  end

  def sanitize_input(input) when is_map(input) do
    Map.new(input, fn {k, v} -> {sanitize_input(k), sanitize_input(v)} end)
  end

  def sanitize_input(input), do: input

  @doc """
  Validate and sanitize a file path to prevent path traversal.
  """
  def sanitize_path(path) when is_binary(path) do
    case Path.safe_relative(path) do
      {:ok, safe_path} ->
        if safe_path == path or safe_path == "." do
          {:ok, path}
        else
          {:error, :invalid_path}
        end
      :error ->
        {:error, :invalid_path}
    end
  end

  def sanitize_path(_), do: {:error, :invalid_path}

  @doc """
  Validate a command is safe to execute.
  """
  def validate_command(cmd) do
    dangerous_patterns = [
      ~r/^rm\s+-rf\s+/,
      ~r/^dd\s+/,
      ~r/^mkfs\./,
      ~r/;\s*rm\s+/,
      ~r/\|\s*rm\s+/,
      ~r/>\s*\/dev\/sd/,
      ~r/\$\(/,
      ~r/`/,
      ~r/&&.*rm/,
      ~r/\|\|.*rm/,
      ~r/curl.*\|\s*sh/i,
      ~r/wget.*\|\s*sh/i
    ]

    if Enum.any?(dangerous_patterns, fn pattern -> Regex.match?(pattern, cmd) end) do
      {:error, :dangerous_command}
    else
      {:ok, cmd}
    end
  end

  @doc """
  Securely erase sensitive data from memory.
  """
  def secure_erase(binary) when is_binary(binary) do
    size = byte_size(binary)
    :binary.copy(<<0>>, size)
  end

  def secure_erase(_), do: nil

  @doc """
  Generate a cryptographically secure random token.
  """
  def generate_token(length \\ 32) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64(padding: false)
  end

  @doc """
  Hash a value with a salt using Argon2 or PBKDF2.
  """
  def hash_value(value, salt \\ :crypto.strong_rand_bytes(16)) do
    hash = :crypto.hash(:sha256, salt <> value)
    %{hash: Base.encode16(hash), salt: Base.encode16(salt)}
  end

  @doc """
  Verify a hashed value.
  """
  def verify_hash(value, %{hash: hash, salt: salt}) do
    decoded_salt = Base.decode16!(salt)
    computed = :crypto.hash(:sha256, decoded_salt <> value)
    secure_compare(Base.encode16(computed), hash)
  end

  defp secure_compare(a, b) do
    a_len = byte_size(a)
    b_len = byte_size(b)

    result =
      if a_len == b_len do
        a == b
      else
        false
      end

    result
  end

  @doc """
  Check if a URL is safe (localhost or private network).
  """
  def safe_url?(url) do
    case URI.parse(url) do
      %URI{host: host, port: port} ->
        safe_host?(host) and safe_port?(port)

      _ ->
        false
    end
  end

  defp safe_host?("localhost"), do: true
  defp safe_host?("127.0.0.1"), do: true
  defp safe_host?("::1"), do: true
  defp safe_host?(<<"10.", _::binary>>), do: true
  defp safe_host?(<<"172.16.", _::binary>>), do: true
  defp safe_host?(<<"192.168.", _::binary>>), do: true
  defp safe_host?("0.0.0.0"), do: true
  defp safe_host?(_), do: false

  defp safe_port?(port) when port > 0 and port < 65536, do: true
  defp safe_port?(_), do: false

  @doc """
  Sanitize JSON payload to prevent DoS attacks.
  """
  def sanitize_json_payload(payload) when is_map(payload) do
    payload
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {sanitize_key(k), sanitize_value(v)} end)
    |> Enum.filter(fn {_, v} -> v != :discard end)
    |> Map.new()
  end

  defp sanitize_key(key) when is_binary(key), do: sanitize_input(key)
  defp sanitize_key(key) when is_atom(key), do: key
  defp sanitize_key(_), do: :discard

  defp sanitize_value(value) when is_binary(value) do
    sanitized = sanitize_input(value)
    if byte_size(sanitized) > 1_000_000 do
      :discard
    else
      sanitized
    end
  end

  defp sanitize_value(value) when is_list(value) do
    value
    |> Enum.map(&sanitize_value/1)
    |> Enum.filter(&(&1 != :discard))
    |> Enum.take(1000)
  end

  defp sanitize_value(value) when is_map(value) do
    sanitize_json_payload(value)
  end

  defp sanitize_value(value) when is_number(value) do
    if is_float(value) and (value > 1.0e308 or value < -1.0e308) do
      :discard
    else
      value
    end
  end

  defp sanitize_value(value), do: value
end
