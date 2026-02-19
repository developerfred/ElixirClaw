defmodule ElixirClaw.Auth do
  @moduledoc """
  Authentication and device identity management.
  """

  alias __MODULE__

  defstruct [:device_id, :public_key, :private_key, :node_id, :token, :secret_key]

  @doc """
  Generate a new device identity using Ed25519 cryptography.
  Returns an Auth struct with private/public key pair.
  """
  def generate_identity do
    device_id = "device_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))

    # Generate Ed25519 key pair
    {private_key_raw, public_key_raw} = :crypto.generate_key(:eddsa, :ed25519)

    %Auth{
      device_id: device_id,
      public_key: Base.encode64(public_key_raw, padding: false),
      private_key: Base.encode64(private_key_raw, padding: false),
      secret_key: nil,
      node_id: nil,
      token: nil
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
  Sign a challenge with the device private key using Ed25519.
  """
  def sign_challenge(%Auth{private_key: private_key}, challenge) when is_binary(private_key) do
    decoded_private = Base.decode64!(private_key, padding: false)

    # Ed25519 signature using :crypto module
    :crypto.sign(:eddsa, :none, challenge, [decoded_private, :ed25519])
    |> Base.encode64(padding: false)
  end

  # Backward compatibility for old HMAC-based identities
  def sign_challenge(%Auth{secret_key: secret_key}, challenge) when is_binary(secret_key) do
    decoded_secret = Base.decode64!(secret_key, padding: false)
    signature = :crypto.mac(:hmac, :sha256, decoded_secret, challenge)
    Base.encode64(signature, padding: false)
  end

  @doc """
  Verify a signature using Ed25519 public key.
  """
  def verify_signature(%Auth{public_key: public_key}, challenge, signature)
      when is_binary(public_key) and is_binary(signature) do
    decoded_public = Base.decode64!(public_key, padding: false)
    decoded_sig = Base.decode64!(signature, padding: false)

    # Ed25519 verification using :crypto module
    :crypto.verify(:eddsa, :none, challenge, decoded_sig, [decoded_public, :ed25519])
  end

  # Backward compatibility for old HMAC-based identities
  def verify_signature(%Auth{secret_key: key}, challenge, signature)
      when is_binary(key) and is_binary(signature) do
    decoded_key = Base.decode64!(key, padding: false)
    decoded_sig = Base.decode64!(signature, padding: false)

    computed = :crypto.mac(:hmac, :sha256, decoded_key, challenge)
    computed == decoded_sig
  end

  defp set_permissions(path) do
    case :os.type() do
      {:unix, _} ->
        System.cmd("chmod", ["600", path])
        :ok

      _ ->
        :ok
    end
  end
end
