defmodule Mix.Tasks.Repl do
  use Mix.Task

  @shortdoc "Runs the ke REPL"
  def run(_), do: Ke.repl
end
