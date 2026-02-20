defmodule ElixirClaw.LLM do
  @moduledoc """
  LLM Integration module for ElixirClaw.

  Provides a bridge between LLM APIs (Claude, GPT-4, NVIDIA, OpenRouter, OpenCode) and ElixirClaw capabilities.
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
      export NVIDIA_API_KEY=your_key_here
      export OPENROUTER_API_KEY=your_key_here
      export OPENCODE_API_KEY=your_key_here

  ## Providers

  - `:claude` - Anthropic Claude (default)
  - `:openai` - OpenAI GPT-4
  - `:nvidia` - NVIDIA NIM API
  - `:openrouter` - OpenRouter (multi-model)
  - `:opencode` - OpenCode API
  """

  @providers [:claude, :openai, :nvidia, :openrouter, :opencode]

  @doc """
  Unified chat interface - automatically selects provider based on opts.

  ## Options

    * `:provider` - Provider atom (:claude, :openai, :nvidia, :openrouter, :opencode)
    * `:api_key` - API key (or use environment variable)
    * `:model` - Model identifier
    * `:node_id` - Node ID for command execution

  ## Examples

      iex> ElixirClaw.LLM.chat("Take a screenshot", provider: :nvidia)
      {:ok, "I've captured a screenshot..."}

      iex> ElixirClaw.LLM.chat("What's my location?", provider: :openrouter, model: "anthropic/claude-3-opus")
      {:ok, "Your location is..."}
  """
  def chat(message, opts \\ []) do
    provider = opts[:provider] || :claude

    case provider do
      :claude -> chat_with_claude(message, opts)
      :openai -> chat_with_gpt4(message, opts)
      :nvidia -> chat_with_nvidia(message, opts)
      :openrouter -> chat_with_openrouter(message, opts)
      :opencode -> chat_with_opencode(message, opts)
      _ -> {:error, {:unknown_provider, provider}}
    end
  end

  @doc """
  List available providers.
  """
  def providers, do: @providers

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
  Chat with NVIDIA NIM API and execute ElixirClaw commands.

  NVIDIA NIM provides access to various models including Llama, Mistral, etc.

  ## Options

    * `:api_key` - NVIDIA API key (or NVIDIA_API_KEY env var)
    * `:model` - Model name (default: "meta/llama-3.1-8b-instruct")
    * `:node_id` - Node ID for command execution

  ## Examples

      iex> ElixirClaw.LLM.chat_with_nvidia("Take a screenshot")
      {:ok, "I've taken a screenshot..."}
  """
  def chat_with_nvidia(message, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("NVIDIA_API_KEY")
    model = opts[:model] || "meta/llama-3.1-8b-instruct"
    node_id = opts[:node_id] || "llm_node"

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      system_prompt = build_system_prompt()

      case call_nvidia_api(api_key, model, system_prompt, message) do
        {:ok, response_text} ->
          handle_nvidia_response(response_text, node_id)

        error ->
          error
      end
    end
  end

  @doc """
  Chat with OpenRouter API and execute ElixirClaw commands.

  OpenRouter provides unified access to multiple LLM providers.

  ## Options

    * `:api_key` - OpenRouter API key (or OPENROUTER_API_KEY env var)
    * `:model` - Model name (default: "anthropic/claude-3.5-sonnet")
    * `:node_id` - Node ID for command execution

  ## Examples

      iex> ElixirClaw.LLM.chat_with_openrouter("Take a screenshot", model: "openai/gpt-4-turbo")
      {:ok, "I've taken a screenshot..."}
  """
  def chat_with_openrouter(message, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("OPENROUTER_API_KEY")
    model = opts[:model] || "anthropic/claude-3.5-sonnet"
    node_id = opts[:node_id] || "llm_node"

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      system_prompt = build_system_prompt()

      case call_openrouter_api(api_key, model, system_prompt, message) do
        {:ok, response_text} ->
          handle_openrouter_response(response_text, node_id)

        error ->
          error
      end
    end
  end

  @doc """
  Chat with OpenCode API and execute ElixirClaw commands.

  OpenCode provides AI coding assistance and device control.

  ## Options

    * `:api_key` - OpenCode API key (or OPENCODE_API_KEY env var)
    * `:model` - Model name (default: "opencode-default")
    * `:node_id` - Node ID for command execution
    * `:base_url` - OpenCode API base URL (default: "https://api.opencode.ai/v1")

  ## Examples

      iex> ElixirClaw.LLM.chat_with_opencode("Take a screenshot")
      {:ok, "I've taken a screenshot..."}
  """
  def chat_with_opencode(message, opts \\ []) do
    api_key = opts[:api_key] || System.get_env("OPENCODE_API_KEY")
    model = opts[:model] || "opencode-default"
    node_id = opts[:node_id] || "llm_node"

    base_url =
      opts[:base_url] || System.get_env("OPENCODE_BASE_URL") || "https://api.opencode.ai/v1"

    if is_nil(api_key) do
      {:error, :missing_api_key}
    else
      system_prompt = build_system_prompt()

      case call_opencode_api(api_key, model, system_prompt, message, base_url) do
        {:ok, response_text} ->
          handle_opencode_response(response_text, node_id)

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

  defp call_nvidia_api(api_key, model, system_prompt, message) do
    url = "https://integrate.api.nvidia.com/v1/chat/completions"

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]

    body = %{
      model: model,
      messages: [
        %{role: "system", content: system_prompt},
        %{role: "user", content: message}
      ],
      max_tokens: 1024,
      temperature: 0.7,
      top_p: 1.0
    }

    case make_post_request(url, headers, body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
        {:ok, content}

      {:ok, %{"error" => %{"message" => error_msg}}} ->
        {:error, error_msg}

      error ->
        error
    end
  end

  defp call_openrouter_api(api_key, model, system_prompt, message) do
    url = "https://openrouter.ai/api/v1/chat/completions"

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"},
      {"http-referer", "https://elixirclaw.dev"},
      {"x-title", "ElixirClaw"}
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

      {:ok, %{"error" => %{"message" => error_msg}}} ->
        {:error, error_msg}

      error ->
        error
    end
  end

  defp call_opencode_api(api_key, model, system_prompt, message, base_url) do
    url = "#{base_url}/chat/completions"

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
      max_tokens: 1024,
      stream: false
    }

    case make_post_request(url, headers, body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
        {:ok, content}

      {:ok, %{"response" => response}} ->
        {:ok, response}

      {:ok, %{"error" => error_msg}} when is_binary(error_msg) ->
        {:error, error_msg}

      {:ok, %{"error" => %{"message" => error_msg}}} ->
        {:error, error_msg}

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

  defp handle_nvidia_response(response_text, node_id) do
    {:ok, response_text}
  end

  defp handle_openrouter_response(response_text, node_id) do
    {:ok, response_text}
  end

  defp handle_opencode_response(response_text, node_id) do
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
