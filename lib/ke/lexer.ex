defmodule Ke.Lexer do
  # Can I just replace the entire Lexer with ~w// ?

  def lex(string), do: lex(string, [], "") |> Enum.reverse

  defp lex("", acc, ""), do: acc
  defp lex("", acc, stack), do: [String.reverse(stack) | acc]

  defp lex("\"" <> rest, acc, "`"), do: lex_string(rest, acc, "\"`")
  defp lex("\"" <> rest, acc, ""), do: lex_string(rest, acc, "\"")

  @symbols ~W": ; , + ( ) ! * @ # - < > _ % ^ & | ? ~ ="
  defp lex(<<c::binary - size(1), rest::binary>>, acc, "") when c in @symbols do
    lex(rest, [c | acc], "")
  end
  defp lex(<<c::binary - size(1), _::binary>> = input, acc, stack) when c in @symbols do
    lex(input, [String.reverse(stack) | acc], "")
  end
  defp lex("/" <> _, acc, _), do: acc
  defp lex(" " <> rest, acc, "") do
    lex(rest, acc, "")
  end
  defp lex(" " <> rest, acc, stack) do
    lex(rest, [String.reverse(stack) | acc], "")
  end
  defp lex(<<c::binary - size(1), rest::binary>>, acc, stack) do
    lex(rest, acc, c <> stack)
  end

  defp lex_string("", _, stack) do
    raise RuntimeError, message: "Terminating string quote missing: #{String.reverse(stack)}"
  end
  defp lex_string("\"" <> rest, acc, stack) do
    lex(rest, [String.reverse("\"" <> stack) | acc], "")
  end
  defp lex_string(<<c::binary - size(1), rest::binary>>, acc, stack) do
    lex_string(rest, acc, c <> stack)
  end
end
