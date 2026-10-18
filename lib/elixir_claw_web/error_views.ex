defmodule ElixirClawWeb.ErrorHTML do
  @moduledoc false

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule ElixirClawWeb.ErrorJSON do
  @moduledoc false

  def render(template, _assigns) do
    %{error: Phoenix.Controller.status_message_from_template(template)}
  end
end
