defmodule Ke do
  alias Ke.Lexer, as: Lexer
  alias Ke.Tokenizer, as: Tokenizer
  alias Ke.Evaluator, as: Evaluator
  alias Ke.Printer, as: Printer

  def repl do
    IO.puts "Welcome to ke. Enter \\h for help, \\intro for an introduction, or \\\\ to quit."
    repl(%{})
  end
  def repl(env) do
    {reply, new_env} = 
      read()
      |> interpret_env(env)

    case reply do
      nil ->
        IO.write(reply)
      {:cmd, :exit} ->
        IO.puts "Exiting.."
        System.stop()
      r ->
        IO.puts(r)
    end
    repl(new_env)
  end

  # Still need to split file by \n now that we have AST parsing?
  def run_file(file) do
    {:ok, content} = File.read(file)

    content
    |> String.trim
    |> String.split("\n")
    |> Enum.reduce(%{}, fn (line, env) ->
      {reply, new_env} = interpret_env(line, env)
      if reply, do: IO.puts(reply)
      new_env
    end)
  end

  defp read, do: IO.gets("  ") |> String.trim()

  # rewrite this as interpret_env but throw reply away?
  def interpret(str) do
    {reply, _} = str
                 |> Lexer.lex()
                 |> Tokenizer.parse()
                 |> Evaluator.eval()
    Printer.tf(reply)
  end

  def interpret_env(str, env \\ %{}) do
    {reply, new_env} = str
                       |> Lexer.lex()
                       |> Tokenizer.parse()
                       |> Evaluator.eval(env)
    {Printer.tf(reply), new_env}
  end
end
