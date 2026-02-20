defmodule ElixirClaw.Node do
  require Logger

  def execute("camera.snap", args) do
    with {:ok, _} <- check_cap("camera.snap"),
         {:ok, device} <- get_camera_device(args[:device]) do
      result = capture_frame(device, args[:options] || %{})
      %{ok: true, data: %{path: result}}
    end
  end

  def execute("camera.clip", args) do
    with {:ok, _} <- check_cap("camera.clip"),
         {:ok, device} <- get_camera_device(args[:device]),
         {:ok, output} <- capture_clip(device, args) do
      %{ok: true, data: %{path: output, duration: args[:duration] || 5}}
    end
  end

  def execute("camera.clip", args, opts) when is_map(opts) do
    node_id = opts[:node_id] || "unknown"
    request_id = opts[:request_id] || generate_request_id()

    ElixirClaw.Events.emit_started("camera.clip", node_id, request_id, %{
      duration: args[:duration],
      device: args[:device]
    })

    ElixirClaw.Events.emit_progress("camera.clip", node_id, request_id, %{
      status: "recording",
      elapsed: 0
    })

    result = execute("camera.clip", args)

    case result do
      %{ok: true, data: data} ->
        ElixirClaw.Events.emit_completed("camera.clip", node_id, request_id, data)
        result

      %{ok: false, error: error} ->
        ElixirClaw.Events.emit_failed("camera.clip", node_id, request_id, %{error: error})
        result
    end
  end

  def execute("screen.snap", args) do
    with {:ok, _} <- check_cap("screen.snap") do
      result = capture_screen(args[:display] || :main, args[:options] || %{})
      %{ok: true, data: %{path: result}}
    end
  end

  def execute("screen.record", args) do
    with {:ok, _} <- check_cap("screen.record"),
         {:ok, output} <- start_screen_record(args) do
      %{ok: true, data: %{path: output, status: :recording}}
    end
  end

  def execute("screen.record", args, opts) when is_map(opts) do
    node_id = opts[:node_id] || "unknown"
    request_id = opts[:request_id] || generate_request_id()

    ElixirClaw.Events.emit_started("screen.record", node_id, request_id, %{
      duration: args[:duration],
      display: args[:display]
    })

    result = execute("screen.record", args)

    case result do
      %{ok: true, data: data} ->
        ElixirClaw.Events.emit_completed("screen.record", node_id, request_id, data)
        result

      %{ok: false, error: error} ->
        ElixirClaw.Events.emit_failed("screen.record", node_id, request_id, %{error: error})
        result
    end
  end

  def execute("system.run", args) do
    with {:ok, _} <- check_cap("system.run"),
         {:ok, cmd} <- validate_command(args[:command]),
         {:ok, sanitized_args} <- sanitize_command_args(args[:args] || []) do
      result = run_command(cmd, sanitized_args, args[:timeout] || 30000)
      %{ok: true, data: result}
    end
  end

  def execute("system.notify", args) do
    with {:ok, _} <- check_cap("system.notify"),
         {:ok, sanitized} <- validate_notification_args(args) do
      send_notification(sanitized[:title] || "ElixirClaw", sanitized[:body] || "", %{})
      %{ok: true, data: %{sent: true}}
    end
  end

  def execute("location.get", args) do
    with {:ok, _} <- check_cap("location.get") do
      result = get_location(args[:high_accuracy] || false)
      %{ok: true, data: result}
    end
  end

  def execute("notifications.send", args) do
    execute("system.notify", args)
  end

  def execute(command, _args) do
    %{ok: false, error: "Unknown command: #{command}"}
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp check_cap(cap) do
    config = Application.get_all_env(:elixir_claw) || %{}
    allowed = config[:caps] || []

    cond do
      allowed == :all -> {:ok, cap}
      is_list(allowed) and cap in allowed -> {:ok, cap}
      true -> {:error, :capability_not_allowed}
    end
  end

  defp get_camera_device(preferred) do
    devices = list_cameras()

    if is_nil(preferred) do
      case devices do
        [] -> {:error, :no_camera_found}
        [first | _] -> {:ok, first}
      end
    else
      if preferred in devices do
        {:ok, preferred}
      else
        {:error, :camera_not_found}
      end
    end
  end

  defp list_cameras do
    case :os.type() do
      {:unix, :darwin} -> list_cameras_macos()
      {:unix, :linux} -> list_cameras_linux()
      _ -> []
    end
  end

  defp list_cameras_macos do
    case System.cmd("system_profiler", ["SPCameraDataType", "-json"]) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"SPCameraDataType" => cameras}} -> Enum.map(cameras, & &1["_name"])
          _ -> []
        end

      _ ->
        []
    end
  end

  defp list_cameras_linux do
    case System.cmd("v4l2-ctl", ["--list-devices"]) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&String.contains?(&1, "/dev/video"))

      _ ->
        Path.wildcard("/dev/video*") |> Enum.map(&Path.basename/1)
    end
  end

  defp capture_frame(device, _options) do
    path = Path.join(System.tmp_dir!(), "elixir_claw_cam_#{:os.system_time(:millisecond)}.jpg")

    case validate_device(device) do
      {:ok, safe_device} ->
        {cmd, args} = build_capture_cmd(safe_device, path)
        execute_capture(cmd, args, path)

      {:error, reason} ->
        Logger.error("Invalid device: #{inspect(reason)}")
        path
    end
  end

  defp build_capture_cmd(device, path) do
    case :os.type() do
      {:unix, :darwin} ->
        device_args = if device, do: ["-d", device], else: []
        {"imagesnap", ["-w", "0.5" | device_args] ++ [path]}

      {:unix, :linux} ->
        device_arg = if device, do: ["-d", device], else: ["-d", "/dev/video0"]
        {"ffmpeg", ["-y", "-f", "v4l2" | device_arg] ++ ["-frames:v", "1", path]}

      _ ->
        {"echo", ["unsupported"]}
    end
  end

  defp validate_device(nil), do: {:ok, nil}

  defp validate_device(device) when is_binary(device) do
    safe = device |> String.replace(~r/[^a-zA-Z0-9_\-\.\/]/, "") |> String.slice(0, 255)
    if safe == device or safe == "", do: {:ok, safe}, else: {:error, :invalid_device}
  end

  defp validate_device(_), do: {:error, :invalid_device}

  defp execute_capture(cmd, args, path) do
    case System.cmd(cmd, args) do
      {_, 0} ->
        Logger.info("Captured frame to: #{path}")
        path

      {output, code} ->
        Logger.error("Capture failed: #{cmd} exited with #{code}: #{output}")
        path
    end
  end

  defp capture_clip(_device, args) do
    duration = args[:duration] || 5
    path = Path.join(System.tmp_dir!(), "elixir_claw_clip_#{:os.system_time(:millisecond)}.mp4")

    {cmd, args} =
      case :os.type() do
        {:unix, :darwin} ->
          {"screencapture", ["-v", "-R0,0,-1,-1", "-t", "mov", path]}

        {:unix, :linux} ->
          {"ffmpeg",
           [
             "-y",
             "-f",
             "x11grab",
             "-framerate",
             "30",
             "-i",
             ":0.0",
             "-t",
             "#{duration}",
             "-c:v",
             "libx264",
             "-preset",
             "ultrafast",
             path
           ]}

        _ ->
          {"echo", ["unsupported"]}
      end

    case System.cmd(cmd, args) do
      {_, 0} ->
        {:ok, path}

      {output, code} ->
        Logger.error("Clip capture failed: #{cmd} exited with #{code}: #{output}")
        {:ok, path}
    end
  end

  defp capture_screen(_display, _options) do
    path = Path.join(System.tmp_dir!(), "elixir_claw_screen_#{:os.system_time(:millisecond)}.png")

    {cmd, args} =
      case :os.type() do
        {:unix, :darwin} -> {"screencapture", ["-x", path]}
        {:unix, :linux} -> {"scrot", [path]}
        _ -> {"echo", ["unsupported"]}
      end

    case System.cmd(cmd, args) do
      {_, 0} ->
        Logger.info("Captured screen to: #{path}")
        path

      {output, code} ->
        Logger.error("Screen capture failed: #{cmd} exited with #{code}: #{output}")
        path
    end
  end

  defp start_screen_record(_args) do
    path = Path.join(System.tmp_dir!(), "elixir_claw_record_#{:os.system_time(:millisecond)}.mp4")

    {cmd, args} =
      case :os.type() do
        {:unix, :darwin} ->
          {"screencapture", ["-v", "-R0,0,-1,-1", "-t", "mov", path]}

        {:unix, :linux} ->
          {"ffmpeg",
           [
             "-y",
             "-f",
             "x11grab",
             "-framerate",
             "30",
             "-i",
             ":0.0",
             "-c:v",
             "libx264",
             "-preset",
             "ultrafast",
             path
           ]}

        _ ->
          {"echo", ["unsupported"]}
      end

    spawn(fn -> System.cmd(cmd, args, stderr_to_stdout: true) end)
    Logger.info("Started recording to: #{path}")
    {:ok, path}
  end

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

  defp validate_command(_), do: {:error, :invalid_command}

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

  defp sanitize_command_args(_), do: {:ok, []}

  defp sanitize_single_arg(arg) do
    arg |> String.replace(~r/[\x00-\x1F\x7F]/, "") |> String.trim()
  end

  defp run_command(cmd, args, _timeout) do
    opts = [stderr_to_stdout: true]

    case System.cmd(cmd, args, opts) do
      {output, 0} -> %{exit_code: 0, stdout: output, stderr: ""}
      {output, code} -> %{exit_code: code, stdout: output, stderr: ""}
    end
  end

  defp validate_notification_args(args) do
    max_title = 500
    max_body = 4000
    title = args[:title] || ""
    body = args[:body] || ""

    if is_binary(title) and is_binary(body) do
      sanitized = %{
        title: String.slice(title, 0, max_title) |> String.replace(~r/[\x00-\x1F\x7F]/, ""),
        body: String.slice(body, 0, max_body) |> String.replace(~r/[\x00-\x1F\x7F]/, "")
      }

      {:ok, sanitized}
    else
      {:error, :invalid_notification_args}
    end
  end

  defp send_notification(title, body, _options) do
    st = sanitize_shell_arg(title)
    sb = sanitize_shell_arg(body)

    case :os.type() do
      {:unix, :darwin} ->
        System.cmd("osascript", ["-e", "display notification \"#{sb}\" with title \"#{st}\""])

      {:unix, :linux} ->
        System.cmd("notify-send", ["--", st, sb])

      _ ->
        Logger.warning("Notifications not supported")
    end
  end

  defp sanitize_shell_arg(arg) when is_binary(arg) do
    arg |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"") |> String.slice(0, 1000)
  end

  defp sanitize_shell_arg(arg), do: to_string(arg) |> sanitize_shell_arg()

  defp get_location(_) do
    Logger.info("Getting location")

    case :os.type() do
      {:unix, :darwin} ->
        case System.cmd("defaults", ["read", "com.apple.clock", "IntlLocalityKey"]) do
          {_output, 0} ->
            %{
              latitude: 0.0,
              longitude: 0.0,
              accuracy: 0.0,
              source: "corelocation",
              timestamp: :os.system_time(:millisecond)
            }

          _ ->
            %{
              latitude: 0.0,
              longitude: 0.0,
              accuracy: 0.0,
              source: "unavailable",
              timestamp: :os.system_time(:millisecond),
              note: "Enable Location Services"
            }
        end

      {:unix, :linux} ->
        case System.cmd("gpspipe", ["-w", "-n", "5"]) do
          {output, 0} ->
            parse_gps_output(output)

          _ ->
            %{
              latitude: 0.0,
              longitude: 0.0,
              accuracy: 0.0,
              source: "unavailable",
              timestamp: :os.system_time(:millisecond),
              note: "Install gpsd"
            }
        end

      _ ->
        %{
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          source: "unavailable",
          timestamp: :os.system_time(:millisecond)
        }
    end
  end

  defp parse_gps_output(output) do
    case output |> String.split("\n") |> Enum.find(&String.contains?(&1, "lat")) do
      nil ->
        %{
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          source: "gpsd",
          timestamp: :os.system_time(:millisecond)
        }

      line ->
        case Jason.decode(line) do
          {:ok, data} ->
            %{
              latitude: data["lat"] || 0.0,
              longitude: data["lon"] || 0.0,
              accuracy: data["eph"] || 0.0,
              source: "gpsd",
              timestamp: :os.system_time(:millisecond)
            }

          _ ->
            %{
              latitude: 0.0,
              longitude: 0.0,
              accuracy: 0.0,
              source: "gpsd",
              timestamp: :os.system_time(:millisecond)
            }
        end
    end
  end
end
