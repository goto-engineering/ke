defmodule D do
  defmacro bug(anything, label \\ nil) do
    suggested_label = case anything do
      {var, _, _} when is_atom(var) -> var
      _ -> label
    end
    quote do
      result = unquote(anything)
      IO.inspect(result, label: unquote(label || suggested_label))
      result
    end
  end
end
