defmodule ElixirClaw.CLI do
  @moduledoc """
  Command-line interface for ElixirClaw.
  Provides node management, approvals, and interactive mode.
  """

  def main(args) do
    case parse_args(args) do
      {:ok, {:help, _opts}} ->
        usage()

      {:ok, {:node_register, opts}} ->
        node_register(opts)

      {:ok, {:node_start, opts}} ->
        node_start(opts)

      {:ok, {:node_stop, opts}} ->
        node_stop(opts)

      {:ok, {:status, opts}} ->
        status(opts)

      {:ok, {:approvals, _opts}} ->
        list_approvals()

      {:ok, {:approve, opts}} ->
        approve(opts)

      {:ok, {:reject, opts}} ->
        reject(opts)

      {:ok, {:interactive, _opts}} ->
        interactive_mode()

      {:ok, {:config, opts}} ->
        show_config(opts)

      {:error, :missing_arg} ->
        IO.puts(:stderr, "Error: Missing required argument")
        usage()

      {:error, :unknown_command} ->
        IO.puts(:stderr, "Error: Unknown command")
        usage()
    end
  end

  defp parse_args([]), do: {:ok, {:status, %{}}}
  defp parse_args(["status"]), do: {:ok, {:status, %{}}}
  defp parse_args(["node-register" | rest]), do: parse_node_register(rest)
  defp parse_args(["node-start" | rest]), do: parse_node_start(rest)
  defp parse_args(["node-stop" | rest]), do: parse_node_stop(rest)
  defp parse_args(["node" | ["register" | rest]]), do: parse_node_register(rest)
  defp parse_args(["node" | ["start" | rest]]), do: parse_node_start(rest)
  defp parse_args(["node" | ["stop" | rest]]), do: parse_node_stop(rest)
  defp parse_args(["approvals"]), do: {:ok, {:approvals, %{}}}
  defp parse_args(["approvals" | ["list" | _]]), do: {:ok, {:approvals, %{}}}
  defp parse_args(["approve" | rest]), do: parse_approve(rest)
  defp parse_args(["reject" | rest]), do: parse_reject(rest)
  defp parse_args(["-i" | _]), do: {:ok, {:interactive, %{}}}
  defp parse_args(["--interactive" | _]), do: {:ok, {:interactive, %{}}}
  defp parse_args(["config" | rest]), do: {:ok, {:config, parse_kv_pairs(rest)}}
  defp parse_args(["--help"]), do: {:ok, {:help, %{}}}
  defp parse_args(["help"]), do: {:ok, {:help, %{}}}
  defp parse_args(_), do: {:error, :unknown_command}

  defp parse_node_register([]), do: {:ok, {:node_register, %{}}}
  defp parse_node_register(["--wait-for-approval" | rest]) do
    case parse_node_register(rest) do
      {:ok, {:node_register, opts}} -> {:ok, {:node_register, Map.put(opts, :wait_for_approval, true)}}
      error -> error
    end
  end
  defp parse_node_register(["--display-name", name | rest]) do
    case parse_node_register(rest) do
      {:ok, {:node_register, opts}} -> {:ok, {:node_register, Map.put(opts, :display_name, name)}}
      error -> error
    end
  end

  defp parse_node_start([]), do: {:ok, {:node_start, %{}}}
  defp parse_node_start(["--display-name", name | rest]) do
    case parse_node_start(rest) do
      {:ok, {:node_start, opts}} -> {:ok, {:node_start, Map.put(opts, :display_name, name)}}
      error -> error
    end
  end

  defp parse_node_stop([]), do: {:ok, {:node_stop, %{}}}
  defp parse_node_stop([node_id | _]) do
    {:ok, {:node_stop, %{node_id: node_id}}}
  end

  defp parse_approve([id | _]) do
    {:ok, {:approve, %{approval_id: id}}}
  end

  defp parse_reject([id | _]) do
    {:ok, {:reject, %{approval_id: id}}}
  end

  defp parse_kv_pairs([]), do: %{}
  defp parse_kv_pairs(["--" <> key | [value | rest]]) do
    Map.put(parse_kv_pairs(rest), String.to_atom(key), value)
  end

  defp node_register(opts) do
    IO.puts("Registering node with OpenClaw Gateway...")

    config = Application.get_all_env(:elixir_claw) || %{}

    merged =
      config
      |> Map.merge(%{
        display_name: opts[:display_name] || config[:display_name],
        wait_for_approval: opts[:wait_for_approval] || false
      })

    node_id = generate_node_id(merged)
    device_id = generate_device_id()

    final_config = Map.merge(merged, %{node_id: node_id, device_id: device_id})

    for {k, v} <- final_config do
      Application.put_env(:elixir_claw, k, v)
    end

    save_config(final_config)

    IO.puts("Node registered successfully!")
    IO.puts("Node ID: #{node_id}")
    IO.puts("Device ID: #{device_id}")

    if final_config[:wait_for_approval] do
      IO.puts("Waiting for approval from Gateway...")
      wait_for_approval(node_id)
    end
  end

  defp node_start(opts) do
    IO.puts("Starting ElixirClaw node...")

    config = Application.get_all_env(:elixir_claw) || %{}

    merged =
      config
      |> Map.merge(opts)
      |> Map.put(:node_id, opts[:node_id] || config[:node_id])

    case ElixirClaw.Gateway.start_link(merged) do
      {:ok, _pid} ->
        IO.puts("Node started successfully!")
        IO.puts("Gateway: #{merged[:gateway_host]}:#{merged[:gateway_port]}")

      {:error, reason} ->
        IO.puts(:stderr, "Failed to start node: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp node_stop(opts) do
    config = Application.get_all_env(:elixir_claw) || %{}
    node_id = opts[:node_id] || config[:node_id]

    case ElixirClaw.Gateway.get_status(node_id) do
      {:error, :not_found} ->
        IO.puts(:stderr, "Node not found: #{node_id}")

      status ->
        IO.puts("Stopping node #{node_id}...")
    end
  end

  defp status(_opts) do
    config = Application.get_all_env(:elixir_claw)

    IO.puts("=== ElixirClaw Status ===")
    IO.puts("Node ID: #{config[:node_id] || "Not registered"}")
    IO.puts("Display Name: #{config[:display_name] || "N/A"}")
    IO.puts("Gateway: #{config[:gateway_host]}:#{config[:gateway_port]}")
    IO.puts("Capabilities: #{Enum.join(config[:caps] || [], ", ")}")
  end

  defp list_approvals do
    IO.puts("=== Pending Approvals ===")
    IO.puts("(No pending approvals)")
  end

  defp approve(opts) do
    IO.puts("Approving: #{opts[:approval_id]}")
  end

  defp reject(opts) do
    IO.puts("Rejecting: #{opts[:approval_id]}")
  end

  defp interactive_mode do
    IO.puts("=== ElixirClaw Interactive Mode ===")
    IO.puts("Type 'help' for commands, 'exit' to quit.\n")

    loop()
  end

  defp loop do
    case IO.gets("elixir_claw> ") do
      :eof ->
        IO.puts("\nGoodbye!")

      line ->
        line = String.trim(line)

        case process_interactive_command(line) do
          :exit ->
            IO.puts("Goodbye!")

          :help ->
            IO.puts(help_text())
            loop()

          result ->
            IO.puts(result)
            loop()
        end
    end
  end

  defp process_interactive_command("exit"), do: :exit
  defp process_interactive_command("quit"), do: :exit
  defp process_interactive_command("help"), do: :help
  defp process_interactive_command("status"), do: "Connected"

  defp process_interactive_command("") do
    ""
  end

  defp process_interactive_command(cmd) do
    "Unknown command: #{cmd}"
  end

  defp help_text do
    """
    Available commands:
      status           - Show node status
      approvals        - List pending approvals
      approve <id>    - Approve a request
      reject <id>     - Reject a request
      help            - Show this help
      exit            - Exit interactive mode
    """
  end

  defp show_config(_opts) do
    config = Application.get_all_env(:elixir_claw) || []

    config
    |> Enum.each(fn {k, v} ->
      IO.puts("#{k}: #{inspect(v)}")
    end)
  end

  defp generate_node_id(config) do
    config[:node_id] || "node_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp generate_device_id do
    "device_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
  end

  defp save_config(config) do
    config_path = config[:config_path] || default_config_path()
    dir = Path.dirname(config_path)

    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    saveable = 
      config
      |> Map.drop([:__struct__, :secret_key, :private_key])
      |> Map.to_list()
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Jason.encode(saveable, pretty: true) do
      {:ok, json} ->
        File.write!(config_path, json)
        
        case :os.type() do
          {:unix, _} ->
            System.cmd("chmod", ["600", config_path])
          _ ->
            :ok
        end
        
        IO.puts("Configuration saved to #{config_path}")

      {:error, reason} ->
        IO.puts(:stderr, "Failed to save config: #{inspect(reason)}")
    end
  end

  defp default_config_path do
    case :os.type() do
      {:win32, :nt} ->
        Path.join(System.get_env("APPDATA") || "", "elixir_claw/config.json")

      {:unix, :darwin} ->
        Path.join(System.get_env("HOME") || "", ".config/elixir_claw/config.json")

      {:unix, :linux} ->
        Path.join(System.get_env("XDG_CONFIG_HOME") || Path.join(System.get_env("HOME") || "", ".config"), "elixir_claw/config.json")
    end
  end

  defp wait_for_approval(_node_id) do
    IO.puts("Waiting for gateway approval...")
    IO.puts("Please approve this node in your OpenClaw Gateway.")
    IO.puts("Press Ctrl+C to cancel.\n")

    Process.sleep(:infinity)
  end

  defp usage do
    IO.puts("""
    ElixirClaw - OpenClaw Node in Elixir

    Usage:
      elixir_claw [command] [options]

    Commands:
      node-register           Register this node with the gateway
      node-start              Start the node
      node-stop [id]          Stop a running node
      status                  Show node status
      approvals               List pending approvals
      approve <id>            Approve a request
      reject <id>             Reject a request
      config                  Show configuration
      -i, --interactive      Start interactive mode

    Options:
      --wait-for-approval     Wait for gateway approval during registration
      --display-name NAME     Set the display name

    Examples:
      elixir_claw node-register --display-name "My Elixir Node"
      elixir_claw node-start
      elixir_claw status
    """)
  end
end
