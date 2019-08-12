defmodule Ke.Printer do
  def tf({:error, message}), do: "Error: #{message}"
  def tf(:exit), do: :exit # will this exit when user evaluates `exit?
  def tf({:help, text}), do: text
  def tf({:intro, text}), do: text
  def tf(nil), do: nil
  def tf(:null), do: "Ø"
  def tf(f) when is_float(f), do: Float.round(f, 7) |> Float.to_string()
  def tf(i) when is_integer(i), do: Integer.to_string(i)
  def tf(s) when is_binary(s), do: ~s/"#{s}"/
  def tf({:var, var}), do: var
  def tf({:cmd, cmd}), do: {:cmd, cmd}
  def tf(a) when is_atom(a) do
    str = Atom.to_string(a)
    case String.contains?(str, " ") do
      true ->  ~s/`"#{str}"/
      false -> "`#{str}"
    end
  end
  def tf([v]), do: ",#{v}"
  def tf(l) when is_list(l) do
    error_list = Enum.all?(l, fn
      {:error, _} -> true
      _ -> false
    end)

    print_in_one_line = not error_list and Enum.all?(l, &(is_integer(&1) || is_float(&1)))
    separator = if print_in_one_line, do: " ", else: "\n"
    text = l
           |> Enum.map(&tf/1)
           |> Enum.join(separator)
    if text != "" and not print_in_one_line, do: text <> "\n", else: text
  end
  def tf(map) when is_map(map) do
    table = Map.keys(map)
            |> Enum.map(fn key -> "#{key}|#{tf(map[key])}" end)
            |> Enum.join("\n")
    table <> "\n"
  end
end
