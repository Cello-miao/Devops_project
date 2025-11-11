defmodule SigninProjectWeb.ErrorHelpers do
  @moduledoc false

  # Translate an error message returned by Ecto.Changeset.traverse_errors/2
  def translate_error({msg, opts}) when is_binary(msg) and is_list(opts) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      value = opts |> Keyword.get(String.to_existing_atom(key), key)
      to_string(value)
    end)
  end

  def translate_error(msg), do: msg
end
