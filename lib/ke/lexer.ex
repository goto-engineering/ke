defmodule Ke.Lexer do
  require D
  # Can I just replace the entire Lexer with ~w// ?

  def lex(string), do: (D.bug(string);lex(string, [], "") |> Enum.reverse)

  defp lex("", acc, ""), do: acc
  defp lex("", acc, stack), do: c(acc, stack)

  defp lex("\"" <> rest, acc, "`"), do: lex_string(rest, acc, "\"`")
  defp lex("\"" <> rest, acc, ""), do: lex_string(rest, acc, "\"")

  # need to know if previous char is space :(
  defp lex("-" <> rest, acc, ""), do: lex_neg(rest, acc, "")
  defp lex_neg("", acc, stack) do
    D.bug("end neg")
    D.bug(acc)
    D.bug(stack)
    
    c(acc, stack <> "-")
  end
  defp lex_neg(" " <> rest, acc, ""), do: lex(rest, c(acc, "-"), "")
  defp lex_neg(" " <> rest, acc, stack) do
    lex(rest, c(acc, stack <> "-"), "")
  end
  defp lex_neg(<<c::binary - size(1), rest::binary>>, acc, stack) do
    D.bug(c)
    D.bug(acc)
    D.bug(stack)
    D.bug(rest)
    lex_neg(rest, acc, c <> stack)
  end

  defp c(acc, stack), do: [String.reverse(stack) | acc]

  @symbols ~W": ; , + ( ) ! * @ # - < > _ % ^ & | ? ~ ="
  defp lex(<<c::binary - size(1), rest::binary>>, acc, "") when c in @symbols do
    lex(rest, [c | acc], "")
  end
  defp lex(<<c::binary - size(1), _::binary>> = input, acc, stack) when c in @symbols do
    lex(input, c(acc, stack), "")
  end
  defp lex("/" <> _, acc, _), do: acc
  defp lex(" " <> rest, acc, "") do
    lex(rest, acc, "")
  end
  defp lex(" " <> rest, acc, stack) do
    lex(rest, c(acc, stack), "")
  end
  defp lex(<<c::binary - size(1), rest::binary>>, acc, stack) do
    lex(rest, acc, c <> stack)
  end

  defp lex_string("", _, stack) do
    raise RuntimeError, message: "Terminating string quote missing: #{String.reverse(stack)}"
  end
  defp lex_string("\"" <> rest, acc, stack) do
    lex(rest, c(acc, "\"" <> stack), "")
  end
  defp lex_string(<<c::binary - size(1), rest::binary>>, acc, stack) do
    lex_string(rest, acc, c <> stack)
  end
end
