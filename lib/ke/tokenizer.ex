defmodule Ke.Tokenizer do
  @operators ~W"! + - * %  / & | # < > = ~ @ ^ : _ ? ,"

  def parse([]), do: nil
  def parse(t) when not is_list(t), do: scalarize(t)
  def parse(tokens) do
    Enum.map(tokens, &scalarize/1)
    |> arrayify
    |> listify
    |> codify
  end

  # Can all these passes use an abstraction? Lots of boilerplate

  defp codify(tokens), do: codify(tokens, [], [])
  defp codify([], [], stack), do: c(stack)
  defp codify([], acc, stack), do: {:code, c([c(stack)|acc])}
  defp codify([";"|t], acc, stack), do: codify(t, [c(stack)|acc], [])
  defp codify([h|t], acc, stack), do: codify(t, acc, [h|stack])
  defp codify(t, [], []), do: t


  defp listify(tokens), do: listify(tokens, [], [])
  defp listify([], [], stack) do
    c(stack)
  end
  defp listify([], acc, []), do: c(acc)
  defp listify([], acc, stack) do
    st = c(stack)
    c([st|acc])
  end
  defp listify(["("|t], acc, []) do
    {list, tail} = list_on(t, [])
    listify(tail, [list|acc], [])
  end
  defp listify(["("|t], [], stack) do
    {list, tail} = list_on(t, [])
    listify(tail, [list|stack], [])
  end
  defp listify([h|t], acc, stack), do: listify(t, acc, [h|stack])
  defp listify(t, [], []), do: t

  defp list_on([], acc), do: raise "Missing terminating parenthesis: #{inspect(c(acc))}"
  defp list_on([")"|t], acc) do
    {c(acc), t}
  end
  defp list_on(["("|t], acc) do
    {list, tail} = list_on(t, [])
    list_on(tail, [list|acc])
  end
  defp list_on([";"|t], acc) do
    list_on(t, acc)
  end
  defp list_on([h|t], acc) do
    list_on(t, [h|acc])
  end


  defp arrayify(tokens), do: arrayify(tokens, [], [])
  defp arrayify([], [], stack), do: c(stack)
  defp arrayify([], acc, stack) do
    st = c(stack)
    case st do
      [] ->
        c(acc)
      _ -> 
        c([st|acc])
    end
  end
  defp arrayify([h|t], acc, stack) do
    if is_scalar(h) do
      arrayify(t, acc, [h|stack])
    else
      st = c(stack)
      n = case st do
        [] ->
          [h|acc]
        _ ->
          [h|[st|acc]]
      end
      arrayify(t, n, [])
    end
  end
  defp c([i]), do: i
  defp c(s), do: Enum.reverse(s)


  @boundaries ~W"; ( )"
  defp is_scalar(s) do
    !(is_atom(s) and Atom.to_string(s) in @operators)
    && s not in @boundaries
  end

  defp scalarize(token) do
    [&operator?/1, &int?/1, &float?/1, &string?/1, &cmd?/1, &name?/1, &var?/1]
    |> Enum.reduce(nil, &(&2 || &1.(token)))
  end

  defp operator?(token) do
    if token in @operators do
      String.to_atom(token)
    end
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

  @commands ~W"\\ \h \intro"
  defp cmd?(token) do
    if token in @commands do
      {:cmd, token}
    end
  end

  defp name?(token) do
    case token do
      "`\"" <> name -> String.trim_trailing(name, "\"") |> String.to_atom
      "`" <> name -> name |> String.to_atom
      _ -> nil
    end
  end

  defp var?(token) do
    if token not in @boundaries do
      {:var, token}
    else
      token
    end
  end
end
