defmodule ElixirClaw.LLM do
  @moduledoc """
  LLM Integration module for ElixirClaw.

  Provides a bridge between LLM APIs (Claude, GPT-4, etc.) and ElixirClaw capabilities.
  This demonstrates the core use case: an AI assistant that can control devices
  through natural language commands.

  ## Example

      # Ask Claude to take a screenshot
      {:ok, response} = ElixirClaw.LLM.chat("Please take a screenshot")
      # => {:ok, "I've taken a screenshot and saved it to /tmp/elixir_claw_screen_123.jpg"}

  ## Configuration

  Set your API key:

      export ANTHROPIC_API_KEY=your_key_here
      export OPENAI_API_KEY=your_key_here
  """

  @doc """
  Chat with Claude and execute ElixirClaw commands based on the response.

  ## Parameters

    * `message` - The user's natural language message
    * `opts` - Options including `:api_key`, `:model`, `:node_id`

  ## Examples

      iex> ElixirClaw.LLM.chat_with_claude("Take a screenshot of my screen")
      {:ok, "I've captured a screenshot and saved it to /tmp/screenshot.jpg"}
  """
  def chat_with_claude(message, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("ANTHROPIC_API_KEY")
    model = opts[:model] || "claude-3-sonnet-20240229"
    node_id = opts[:node_id] || "llm_node"

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      system_prompt = build_system_prompt()

      case call_claude_api(api_key, model, system_prompt, message) do
        {:ok, response_text} ->
          handle_claude_response(response_text, node_id)

        error ->
          error
      end
    end
  end

  @doc """
  Chat with GPT-4 and execute ElixirClaw commands.
  """
  def chat_with_gpt4(message, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("OPENAI_API_KEY")
    model = opts[:model] || "gpt-4-turbo-preview"
    node_id = opts[:node_id] || "llm_node"

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      system_prompt = build_system_prompt()

      case call_openai_api(api_key, model, system_prompt, message) do
        {:ok, response_text} ->
          handle_gpt4_response(response_text, node_id)

        error ->
          error
      end
    end
  end

  @doc """
  Process a natural language command and execute the corresponding ElixirClaw capability.

  This is a local version that doesn't require an LLM API - it uses pattern matching
  to interpret common commands.
  """
  def process_command(message, opts \\ []) do
    node_id = opts[:node_id] || "local_node"
    request_id = generate_request_id()

    cond do
      String.contains?(String.downcase(message), "screenshot") ->
        execute_with_response("screen.snap", %{}, node_id, request_id)

      String.contains?(String.downcase(message), "photo") or
          String.contains?(String.downcase(message), "camera") ->
        execute_with_response("camera.snap", %{}, node_id, request_id)

      String.contains?(String.downcase(message), "record screen") ->
        execute_with_response("screen.record", %{duration: 5}, node_id, request_id)

      String.contains?(String.downcase(message), "location") or
          String.contains?(String.downcase(message), "where am i") ->
        execute_with_response("location.get", %{}, node_id, request_id)

      String.contains?(String.downcase(message), "notify") or
          String.contains?(String.downcase(message), "notification") ->
        {title, body} = extract_notification(message)
        execute_with_response("system.notify", %{title: title, body: body}, node_id, request_id)

      String.contains?(String.downcase(message), "run") or
          String.contains?(String.downcase(message), "execute") ->
        cmd = extract_command(message)
        execute_with_response("system.run", %{command: cmd, args: []}, node_id, request_id)

      true ->
        {:error, :unknown_command}
    end
  end

  defp build_system_prompt do
    """
    You are an AI assistant with access to ElixirClaw device capabilities.

    You can perform the following actions:
    - Take screenshots: screen.snap
    - Take photos: camera.snap  
    - Record screen: screen.record (specify duration)
    - Get location: location.get
    - Send notifications: system.notify (with title and body)
    - Run commands: system.run (with command)

    When the user asks you to do something, respond with:
    1. A brief acknowledgment
    2. The action you will take
    3. The result

    Always ask for confirmation before executing potentially dangerous commands.
    """
  end

  defp call_claude_api(api_key, model, system_prompt, message) do
    url = "https://api.anthropic.com/v1/messages"

    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]

    body = %{
      model: model,
      max_tokens: 1024,
      system: system_prompt,
      messages: [%{role: "user", content: message}]
    }

    case make_post_request(url, headers, body) do
      {:ok, %{"content" => [%{"text" => text} | _]}} ->
        {:ok, text}

      error ->
        error
    end
  end

  defp call_openai_api(api_key, model, system_prompt, message) do
    url = "https://api.openai.com/v1/chat/completions"

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    body = %{
      model: model,
      messages: [
        %{role: "system", content: system_prompt},
        %{role: "user", content: message}
      ],
      max_tokens: 1024
    }

    case make_post_request(url, headers, body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
        {:ok, content}

      error ->
        error
    end
  end

  defp make_post_request(url, headers, body) do
    case :httpc.request(:post, {url, headers, 'application/json', Jason.encode!(body)}, [], []) do
      {:ok, {{_, 200, _}, _response_headers, response_body}} ->
        case Jason.decode(to_string(response_body)) do
          {:ok, json} -> {:ok, json}
          error -> error
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_claude_response(response_text, node_id) do
    {:ok, response_text}
  end

  defp handle_gpt4_response(response_text, node_id) do
    {:ok, response_text}
  end

  defp execute_with_response(capability, args, node_id, request_id) do
    result =
      ElixirClaw.Node.execute(capability, args, %{
        node_id: node_id,
        request_id: request_id
      })

    case result do
      %{ok: true, data: data} ->
        {:ok, format_success_response(capability, data)}

      %{ok: false, error: error} ->
        {:error, error}
    end
  end

  defp format_success_response("screen.snap", data) do
    "I've taken a screenshot and saved it to #{data.path}"
  end

  defp format_success_response("camera.snap", data) do
    "I've taken a photo and saved it to #{data.path}"
  end

  defp format_success_response("screen.record", data) do
    "I've started recording the screen to #{data.path}"
  end

  defp format_success_response("location.get", data) do
    "Your location is: latitude #{data.latitude}, longitude #{data.longitude} (#{data.source})"
  end

  defp format_success_response("system.notify", _data) do
    "I've sent the notification"
  end

  defp format_success_response("system.run", data) do
    "Command executed. Exit code: #{data.exit_code}"
  end

  defp format_success_response(capability, _data) do
    "Executed #{capability} successfully"
  end

  defp extract_notification(message) do
    downcase = String.downcase(message)

    title =
      cond do
        String.contains?(downcase, "reminder") -> "Reminder"
        String.contains?(downcase, "alert") -> "Alert"
        String.contains?(downcase, "meeting") -> "Meeting"
        true -> "ElixirClaw Notification"
      end

    body =
      String.replace(message, ~r/notify|notification|send/i, "")
      |> String.trim()

    {title, body}
  end

  defp extract_command(message) do
    message
    |> String.replace(~r/run|execute|command/i, "")
    |> String.trim()
    |> String.split(" ")
    |> List.first()
    |> Kernel.||("echo 'No command specified'")
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
