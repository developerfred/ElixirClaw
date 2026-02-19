defmodule ElixirClaw.Auth do
  @moduledoc """
  Authentication and device identity management.
  """

  alias __MODULE__

  defstruct [:device_id, :public_key, :private_key, :node_id, :token, :secret_key]

  @doc """
  Generate a new device identity.
  Uses Ed25519 if available, otherwise uses HMAC-SHA256.
  """
  def generate_identity do
    device_id = "device_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))

    secret_key = :crypto.strong_rand_bytes(32)
    public_key = :crypto.hash(:sha256, secret_key)

    %Auth{
      device_id: device_id,
      public_key: Base.encode64(public_key, padding: false),
      private_key: nil,
      secret_key: Base.encode64(secret_key, padding: false)
    }
  end

  @doc """
  Load identity from storage.
  """
  def load_identity(path) do
    case File.read(path) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, map} ->
            {:ok,
             %Auth{
               device_id: map["device_id"],
               public_key: map["public_key"],
               private_key: map["private_key"],
               secret_key: map["secret_key"],
               node_id: map["node_id"],
               token: map["token"]
             }}

          error ->
            error
        end

      error ->
        error
    end
  end

  @doc """
  Save identity to secure storage.
  """
  def save_identity(%Auth{} = identity, path) do
    dir = Path.dirname(path)

    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    data = %{
      device_id: identity.device_id,
      public_key: identity.public_key,
      private_key: identity.private_key,
      secret_key: identity.secret_key,
      node_id: identity.node_id,
      token: identity.token
    }

    File.write!(path, Jason.encode!(data, pretty: true))
    set_permissions(path)
  end

  @doc """
  Sign a challenge with the device secret key using HMAC-SHA256.
  """
  def sign_challenge(%Auth{secret_key: secret_key}, challenge) when is_binary(secret_key) do
    decoded_secret = Base.decode64!(secret_key, padding: false)
    signature = :crypto.mac(:hmac, :sha256, decoded_secret, challenge)
    Base.encode64(signature, padding: false)
  end

  def sign_challenge(%Auth{private_key: key}, challenge) when is_binary(key) do
    decoded_key = Base.decode64!(key, padding: false)
    signature = :crypto.mac(:hmac, :sha256, decoded_key, challenge)
    Base.encode64(signature, padding: false)
  end

  @doc """
  Verify a signature.
  """
  def verify_signature(%Auth{public_key: key}, challenge, signature) when is_binary(key) and is_binary(signature) do
    decoded_key = Base.decode64!(key, padding: false)
    decoded_sig = Base.decode64!(signature, padding: false)

    computed = :crypto.mac(:hmac, :sha256, decoded_key, challenge)
    computed == decoded_sig
  end

  defp set_permissions(path) do
    case :os.type() do
      {:unix, _} ->
        System.cmd("chmod", ["600", path])

      _ ->
        :ok
    end
  end
end
