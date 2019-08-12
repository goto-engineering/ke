defmodule Ke.Parser do
  def parse(str) do
    str
    |> String.split("", trim: true)
    |> parse([], [])
  end

  @operators ~W"! + - * %  / & | # < > = ~ @ ^ : _ ? ,"
  @commands ~W"\\ \h \intro"

  defp parse([], [], []), do: []
  defp parse([], acc, []), do: Enum.reverse(acc)
  defp parse([], acc, stack), do: Enum.reverse([collapse_stack(stack) | acc])
  defp parse(input, acc, []) do
    case input do
      ["(" | t] ->
        {list, tail} = parse_list(t)
        parse(tail, [list | acc], [])
      ["\"" | t] ->
        {string, tail} = parse_string(t)
        parse(tail, [string | acc], [])
      ["/" | _] ->
        parse([], acc, [])
      [" " | t] ->
        parse(t, acc, [])
      [h | t] when h in @operators -> 
        parse(t, [String.to_atom(h) | acc], [])
      [h | t] -> parse(t, acc, [h])
    end
  end
  defp parse(input, acc, stack) do
    case input do
      [";" | t] ->
        prev_expr = [collapse_stack(stack) | acc] |> Enum.reverse
        next_expr = parse(t, [], [])
        case next_expr do
          {:code, code} -> {:code, [prev_expr | code]}
          expr -> {:code, [prev_expr | [expr]]}
        end
      [" " | t] ->
        {value, tail} = decide_if_array(t, collapse_stack(stack))
        parse(tail, [value | acc], [])
      ["\"" | t] ->
        {string, tail} = parse_string(t)
        s = String.split(string, "", trim: true) |> Enum.reverse
        c = collapse_stack(s ++ stack)
        parse(tail, [c | acc], [])
      [h | t] when h in @operators -> 
        a = [collapse_stack(stack) | acc]
        parse(t, [String.to_atom(h) | a], [])
      [h | t] -> parse(t, acc, [h | stack])
    end
  end

  defp decide_if_array(input, last_value) do
    case input do
      ["/" | _] ->
        {last_value, []}
      ["\"" | t] ->
        {string, tail} = parse_string(t)
        {array, tail} = parse_array(tail, [])
        b = [string | array]
        {[last_value | b], tail}
      [h | _] = whole when h in @operators ->
        {last_value, whole}
      [h | t] ->
        parse_array(t, [last_value], [h])
    end
  end

  defp parse_array(input, array, stack \\ []) do
    case input do
      [] ->
        ar = [collapse_stack(stack) | array] |> Enum.reverse
        {ar, []}
      [" " | t] ->
        case stack do
          [] ->
            parse_array(t, array)
          _ -> 
            parse_array(t, [collapse_stack(stack) | array])
        end
      [h | _] = whole when h in @operators ->
        ar = case stack do
          [] ->
            Enum.reverse(array)
          _ -> 
            [collapse_stack(stack) | array] |> Enum.reverse
        end
        {ar, whole}
      [h | t] ->
        parse_array(t, array, [h | stack])
    end
  end

  defp parse_list(input, list \\ [], stack \\ []) do
    case input do
      [")" | t] ->
        case stack do
          [] ->
            {Enum.reverse(list), t}
          _ -> list = [collapse_stack(stack) | list] |> Enum.reverse
            {list, t}
        end
      [" " | t] ->
        case stack do
          [] ->
            parse_list(t, list)
          _ -> 
            parse_list(t, [collapse_stack(stack) | list])
        end
      ["\"" | t] ->
        {string, tail} = parse_string(t)
        parse_list(tail, [string | list], [])
      [";" | t] ->
        case stack do
          [] ->
            parse_list(t, list)
          _ -> 
            list1 = [collapse_stack(stack) | list] |> Enum.reverse
            case list do
              [] ->
                parse_list(t, list1)
              _ ->
                {list2, tail} = parse_list(t, [])
                {[list1, list2], tail}
            end
        end
      [h | t] ->
        parse_list(t, list, [h | stack])
    end
  end

  defp parse_string(input, stack \\ []) do
    case input do
      ["\"" | t] ->
        string = stack |> Enum.reverse |> Enum.join("")
        {string, t}
      [h | t] ->
        parse_string(t, [h | stack])
    end
  end

  defp collapse_stack(stack) do
    stack
    |> Enum.reverse
    |> Enum.join("")
    |> scalarize
  end

  defp scalarize(token) do
    [&int?/1, &float?/1, &string?/1, &cmd?/1, &name?/1, &var?/1]
    |> Enum.reduce(nil, &(&2 || &1.(token)))
  end

  defp int?(token) do
    case Integer.parse(token) do
      {i, ""} -> i
      _ -> nil
    end
  end

  defp float?(token) do
    case Float.parse(token) do
      {f, ""} -> f
      _ -> nil
    end
  end

  defp string?(token) when is_binary(token) do
    if String.first(token) == "\"" and String.first(token) == "\"" do
      String.trim(token, "\"")
    end
  end

  defp cmd?(token) do
    if token in @commands do
      {:cmd, token}
    end
  end

  defp name?(token) do
    if String.first(token) == "`" do
      String.to_atom(String.trim_leading(token, "`"))
    end
  end

  defp var?(token) do
    {:var, token}
  end
end
